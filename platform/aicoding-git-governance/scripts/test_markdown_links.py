"""Regression coverage for code/math false references and real Markdown failures."""
import tempfile
from pathlib import Path
import unittest

from validate_markdown_links import anchors, validate


class MarkdownLinksTest(unittest.TestCase):
    def check_document(self, content: str) -> list[str]:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'sample.md'
            path.write_text(content, encoding='utf-8')
            return validate(path)

    def test_c_array_is_not_reference(self):
        self.assertEqual(self.check_document('```c\nfloat covariance[4][4];\n[bad](missing.md)\n```\n'), [])

    def test_inline_math_and_code_are_not_references(self):
        self.assertEqual(self.check_document('$[d,q]=[a,b][\\alpha,\\beta]$ and `float x[4][4]`\n'), [])

    def test_display_math_is_not_reference(self):
        self.assertEqual(self.check_document('$$\n[A][B]\n$$\n'), [])

    def test_real_broken_link_is_rejected(self):
        self.assertIn('missing local target', self.check_document('[bad](missing.md)')[0])

    def test_real_missing_reference_is_rejected(self):
        self.assertIn('missing reference', self.check_document('[text][missing]')[0])

    def test_reference_after_fence_is_validated(self):
        self.assertIn('missing reference', self.check_document('~~~c\n[4][4]\n~~~\n[text][missing]')[0])

    def test_real_heading_and_anchor(self):
        self.assertEqual(self.check_document('# Real heading\n[go](#real-heading)\n'), [])
        self.assertEqual(anchors('```markdown\n# Fake heading\n```\n# Real heading'), {'real-heading'})

    def test_inline_code_remains_in_heading_anchor(self):
        self.assertEqual(self.check_document('# `Code` heading\n[go](#code-heading)\n'), [])


if __name__ == '__main__':
    unittest.main()
