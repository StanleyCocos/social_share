"""Compare retained native method bodies with the exact upstream Git commit.

Usage: python3 tool/verify_migration.py /path/to/flutter_share
The upstream checkout must be at SOURCE_COMMIT. No network or mutation is used.
"""
import re
import subprocess
import sys
from pathlib import Path

SOURCE_COMMIT = '48debc8f1dce843954b8613095af1ac950d3918b'
ROOT = Path(__file__).resolve().parents[1]


def methods(text, objc=False):
    pattern = r'^[-+] \([^\n]+\)\w+' if objc else r'^    (?:private |public |override )?fun \w+'
    result = {}
    for match in re.finditer(pattern, text, re.M):
        opening = text.index('{', match.start())
        depth, end = 1, opening + 1
        while depth:
            depth += (text[end] == '{') - (text[end] == '}')
            end += 1
        header = text[match.start():opening]
        key = re.sub(r'\s+', ' ', header).strip()
        result[key] = text[match.start():end]
    return result


def normalize(text, platform):
    title = platform.capitalize()
    text = text.replace(f'SocialShare{title}Plugin', 'FluttersharePlugin')
    text = text.replace(f'{title}ShareHelper', 'ShareHelper').replace(f'{title}ShareModel', 'ShareModel')
    text = text.replace(f'com.addcn.social_share_{platform}', 'com.addcn.fluttershare')
    text = text.replace(f'.social_share_{platform}.fileprovider', '.share.fileprovider')
    text = text.replace(f'"social_share_{platform}"', '"fluttershare"')
    return re.sub(r'\n{3,}', '\n\n', text)


def compare_methods(source, destination, platform, objc=False, skip=()):
    expected = methods(source, objc)
    actual = methods(normalize(destination, platform), objc)
    removed = (
        ('shareToLine', 'percentEncodeText', 'openLineWebShareWithModel')
        if objc and platform == 'facebook'
        else ('shareToFacebook', 'tryShowFacebookDialogWithContent',
              'fallbackToFacebookWebIfNativeDidNotOpenWithContent',
              'openFacebookWebShareWithModel', 'sharer', 'sharerDidCancel')
        if objc and platform == 'line'
        else ('shareToLine', 'shareTextLine', 'shareImageLine')
        if platform == 'facebook'
        else ('ensureFacebookShareReady', 'shareFacebookInit', 'shareToFacebook',
              'shareTextFacebook', 'shareImageFacebook', 'getBitmapFromUrl')
    )
    retained = {
        header for header in expected
        if not any(re.search(r'\b' + name + r'\b', header) for name in removed)
    }
    assert set(actual) == retained, f'Missing or unexpected native methods: {platform}: {set(actual) ^ retained}'
    count = 0
    for header, body in actual.items():
        if any(re.search(r'\b' + name + r'\b', header) for name in skip):
            continue
        original = expected.get(header)
        if platform == 'line' and objc and 'completeWithState:' in header and original:
            original = original.replace('    self.facebookModel = nil;\n', '')
        assert original is not None, f'Unexpected native method: {header}'
        assert body == re.sub(r'\n{3,}', '\n\n', original), f'Changed native method: {platform}: {header}'
        count += 1
    return count


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    source = Path(sys.argv[1]).resolve()
    revision = subprocess.check_output(['git', '-C', str(source), 'rev-parse', 'HEAD'], text=True).strip()
    assert revision == SOURCE_COMMIT, f'Wrong upstream revision: {revision}'
    # Reject modified upstream files as well as a wrong commit.
    subprocess.run(['git', '-C', str(source), 'diff', '--exit-code', 'HEAD', '--', 'lib', 'android', 'ios'], check=True)
    count = 0
    for platform in ['facebook', 'line']:
        title = platform.capitalize()
        base = ROOT / f'packages/social_share_{platform}'
        original_kt = (source / 'android/src/main/kotlin/com/addcn/fluttershare/FluttersharePlugin.kt').read_text()
        migrated_kt = (base / f'android/src/main/kotlin/com/addcn/social_share_{platform}/SocialShare{title}Plugin.kt').read_text()
        count += compare_methods(original_kt, migrated_kt, platform, skip=('onMethodCall', 'onActivityResult', 'updateActivity'))
        original_helper = (source / 'ios/Classes/Share/ShareHelper.m').read_text()
        migrated_helper = (base / f'ios/Classes/Share/{title}ShareHelper.m').read_text()
        count += compare_methods(original_helper, migrated_helper, platform, objc=True, skip=('shareToPlatformType',))
        original_model = (source / 'ios/Classes/Share/ShareModel.m').read_text()
        migrated_model = (base / f'ios/Classes/Share/{title}ShareModel.m').read_text()
        count += compare_methods(original_model, migrated_model, platform, objc=True)
        for filename in ['WebViewActivity.kt', 'ThreadManager.kt', 'ShareFileProvider.kt']:
            expected = (source / f'android/src/main/kotlin/com/addcn/fluttershare/{filename}').read_text()
            actual = (base / f'android/src/main/kotlin/com/addcn/social_share_{platform}/{filename}').read_text()
            assert normalize(actual, platform) == normalize(expected, platform), filename
        assert (base / 'android/src/main/res/xml/file_path.xml').read_bytes() == (source / 'android/src/main/res/xml/file_path.xml').read_bytes()
    old_model = (source / 'lib/fluttershare.dart').read_text().split('class ShareModel', 1)[1]
    new_model = (ROOT / 'packages/social_share_core/lib/src/share_model.dart').read_text().split('class ShareModel', 1)[1]
    # Dart format only changes whitespace in these declarations.
    def model_tokens(value):
        return re.sub(r',([})])', r'\1', re.sub(r'\s+', '', value))
    assert model_tokens(old_model) == model_tokens(new_model)
    print(f'PASS: {count} retained native method bodies, shared native files and Dart model match {SOURCE_COMMIT}.')
    print('Excluded: platform dispatch/registration and LINE lifecycle hooks after removing Facebook dependencies.')


if __name__ == '__main__':
    main()
