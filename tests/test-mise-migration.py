import importlib.util
from pathlib import Path
import tempfile
import unittest

import tomlkit

spec = importlib.util.spec_from_file_location("migration", Path(__file__).resolve().parents[1] / "scripts/migrate-mise-tools.py")
migration = importlib.util.module_from_spec(spec)
spec.loader.exec_module(migration)


class MigrationTest(unittest.TestCase):
    def test_preserves_user_choices_and_is_repeatable(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "config.toml"
            original = '''# user settings
[tools]
ruff = "latest"
helm = "3.16.0" # pinned by user
"npm:pyright" = { version = "latest", os = ["linux"] }
node = "22"
[settings]
experimental = true
'''
            path.write_text(original)
            path.chmod(0o600)
            names = ["ruff", "helm", "npm:pyright"]
            self.assertEqual(migration.migrate(path, names), ["ruff"])
            text = path.read_text()
            document = tomlkit.parse(text)
            self.assertNotIn("ruff", document["tools"])
            self.assertEqual(document["tools"]["helm"], "3.16.0")
            self.assertEqual(document["tools"]["npm:pyright"]["os"], ["linux"])
            self.assertEqual(document["tools"]["node"], "22")
            self.assertTrue(document["settings"]["experimental"])
            self.assertIn("# pinned by user", text)
            self.assertIn("# user settings", text)
            self.assertEqual(path.stat().st_mode & 0o777, 0o600)
            backups = list(path.parent.glob("config.toml.before-nix-*"))
            self.assertEqual(len(backups), 1)
            self.assertEqual(backups[0].read_text(), original)
            self.assertEqual(migration.migrate(path, names), [])
            self.assertEqual(path.read_text(), text)
            self.assertEqual(list(path.parent.glob("config.toml.before-nix-*")), backups)

    def test_missing_file_and_symlink(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "config.toml"
            self.assertEqual(migration.migrate(path, ["ruff"]), [])
            target = path.parent / "target.toml"
            target.write_text('[tools]\nruff = "latest"\n')
            path.symlink_to(target)
            with self.assertRaises(ValueError):
                migration.migrate(path, ["ruff"])
            self.assertIn('ruff = "latest"', target.read_text())


if __name__ == "__main__":
    unittest.main()
