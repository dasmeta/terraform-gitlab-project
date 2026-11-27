"""Format a generated repository document without changing its data."""
import json
import sys


def format_document(query):
    document = json.loads(query['document'])
    if not isinstance(document, dict):
        raise ValueError('Expected a repository JSON object.')
    return {'content': json.dumps(document, indent=2, ensure_ascii=False, allow_nan=False) + '\n'}


def main():
    json.dump(format_document(json.load(sys.stdin)), sys.stdout, ensure_ascii=False)
    sys.stdout.write('\n')


if __name__ == '__main__':
    try:
        main()
    except (KeyError, TypeError, ValueError):
        print('Unable to format the repository JSON document.', file=sys.stderr)
        sys.exit(1)
