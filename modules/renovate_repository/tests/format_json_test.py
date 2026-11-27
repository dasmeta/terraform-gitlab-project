"""Formatting must preserve special strings and complete embedded manifests."""
import importlib.util
import json
from pathlib import Path
import unittest


spec = importlib.util.spec_from_file_location(
    'format_repository_json', Path(__file__).parents[1] / 'scripts/format_repository_json.py')
formatter = importlib.util.module_from_spec(spec)
spec.loader.exec_module(formatter)


class FormatJsonTest(unittest.TestCase):
    def test_nested_documents_preserve_strings_and_values(self):
        document = {
            'description': ['quotes " newline\n Unicode հայերեն and ${literal}'],
            'packageRules': [{'matchFileNames': ['/^ci-pipelines\\/deploy\\.yml$/'], 'enabled': False}],
            'empty': {}, 'array': [], 'null': None,
        }
        text = formatter.format_document({'document': json.dumps(document)})['content']
        self.assertEqual(json.loads(text), document)
        self.assertIn('\n    {\n      ', text)
        self.assertTrue(text.endswith('\n}\n'))
        self.assertFalse(text.endswith('\n\n'))

    def test_embedded_package_manifest_is_preserved(self):
        document = {'name': 'example', 'dependencies': {'example': '^1.0.0'}, 'renovate': {'automerge': False}}
        text = formatter.format_document({'document': json.dumps(document)})['content']
        self.assertEqual(json.loads(text), document)
        self.assertIn('\n  "renovate": {\n', text)

    def test_invalid_document_rejected(self):
        for document in ('[]', 'null', 'not json'):
            with self.subTest(document=document), self.assertRaises(ValueError):
                formatter.format_document({'document': document})


if __name__ == '__main__':
    unittest.main()
