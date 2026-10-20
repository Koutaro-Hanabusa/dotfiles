import importlib.util
import fcntl
import hashlib
import http.client
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
import urllib.error
from contextlib import redirect_stdout
from unittest.mock import patch


SPEC = importlib.util.spec_from_file_location("kb_save", Path(__file__).with_name("kb-save.py"))
kb_save = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(kb_save)


class KbSaveTest(unittest.TestCase):
    def setUp(self):
        self.event = {
            "hook_event_name": "Stop", "stop_hook_active": False,
            "session_id": "session", "turn_id": "turn",
            "last_assistant_message": "確認済みの知見",
            "transcript_path": "/secret/transcript", "tool_data": "SECRET_TOOL_DATA",
        }
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.cache = Path(self.temp.name)

    def test_disabled_reads_nothing(self):
        with patch.dict(os.environ, {"CODEX_KB_AUTO_SAVE": "0"}), \
                patch.object(kb_save.sys.stdin, "read", side_effect=AssertionError("stdin read")), \
                patch.object(kb_save.urllib.request, "build_opener", side_effect=AssertionError("network")), \
                patch.object(kb_save.Path, "home", side_effect=AssertionError("home read")):
            self.assertIsNone(kb_save.main())

    def test_missing_credentials_reads_nothing(self):
        with patch.dict(os.environ, {"CODEX_KB_AUTO_SAVE": "1", "CLOUDFLARE_ACCOUNT_ID": "invalid",
                                  "CLOUDFLARE_API_TOKEN": "token"}), \
                patch.object(kb_save.sys.stdin, "read", side_effect=AssertionError("stdin read")), \
                patch.object(kb_save.urllib.request, "build_opener", side_effect=AssertionError("network")):
            self.assertIsNone(kb_save.main())

    def test_skips_other_events_active_and_bad_ids(self):
        with patch.object(kb_save, "save_probability", side_effect=AssertionError("network")):
            for change in ({"hook_event_name": "PostToolUse"}, {"stop_hook_active": True},
                           {"turn_id": ""}, {"session_id": 1}, {"last_assistant_message": " "}):
                with self.subTest(change=change):
                    self.assertIsNone(kb_save.handle({**self.event, **change}, "a" * 32, "token", self.cache))

    def test_high_probability_blocks_once_with_fixed_reason(self):
        with patch.object(kb_save, "save_probability", return_value=0.9) as decide:
            answer = kb_save.handle(self.event, "a" * 32, "token", self.cache)
            self.assertEqual(answer, {"decision": "block", "reason": kb_save.REASON})
            self.assertIsNone(kb_save.handle(self.event, "a" * 32, "token", self.cache))
            decide.assert_called_once()
        self.assertNotIn("SECRET_TOOL_DATA", answer["reason"])

    def test_low_probability_is_recorded_and_skipped(self):
        with patch.object(kb_save, "save_probability", return_value=0.2) as decide:
            self.assertIsNone(kb_save.handle(self.event, "a" * 32, "token", self.cache))
            self.assertIsNone(kb_save.handle(self.event, "a" * 32, "token", self.cache))
            decide.assert_called_once()

    def test_failed_call_can_retry(self):
        with patch.object(kb_save, "save_probability", side_effect=[None, 0.9]) as decide:
            self.assertIsNone(kb_save.handle(self.event, "a" * 32, "token", self.cache))
            self.assertIsNotNone(kb_save.handle(self.event, "a" * 32, "token", self.cache))
            self.assertEqual(decide.call_count, 2)

    def test_network_errors_produce_no_output_or_success_marker(self):
        class Opener:
            def __init__(self, error):
                self.error = error

            def open(self, request, timeout):
                raise self.error

        key = hashlib.sha256(json.dumps(["session", "turn"]).encode()).hexdigest()
        for error in (urllib.error.URLError("offline"), http.client.IncompleteRead(b"partial", 10)):
            with self.subTest(error=type(error).__name__), \
                    patch.dict(os.environ, {"CODEX_KB_AUTO_SAVE": "1", "CLOUDFLARE_ACCOUNT_ID": "a" * 32,
                                         "CLOUDFLARE_API_TOKEN": "test-token"}, clear=True), \
                    patch.object(kb_save.sys, "stdin", io.StringIO(json.dumps(self.event))), \
                    patch.object(kb_save.Path, "home", return_value=self.cache), \
                    patch.object(kb_save.urllib.request, "build_opener", return_value=Opener(error)):
                output = io.StringIO()
                with redirect_stdout(output):
                    self.assertIsNone(kb_save.main())
                self.assertEqual(output.getvalue(), "")
                self.assertFalse((self.cache / ".cache/codex-kb-save" / key).exists())

    def test_busy_turn_skips_without_blocking_other_turns(self):
        key = hashlib.sha256(json.dumps(["session", "turn"]).encode()).hexdigest()
        with (self.cache / f"{key}.lock").open("a") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with patch.object(kb_save, "save_probability", return_value=0.2) as decide:
                self.assertIsNone(kb_save.handle(self.event, "a" * 32, "token", self.cache))
                decide.assert_not_called()
                self.assertIsNone(kb_save.handle({**self.event, "turn_id": "other"}, "a" * 32, "token", self.cache))
                decide.assert_called_once()

    def test_request_uses_only_truncated_final_answer(self):
        self.event["last_assistant_message"] = "A" * 20001

        class Opener:
            def open(self, request, timeout):
                self_request = request
                self.assertEqual(timeout, 10)
                self.assertEqual(self_request.full_url, "https://api.cloudflare.com/client/v4/accounts/" + "a" * 32 + "/ai/run/@cf/cloudflare/clef")
                body = json.loads(request.data)
                self.assertEqual(body["state"], "A" * 20000)
                self.assertEqual(body["model"], "clef")
                self.assertEqual(body["questions"]["save"]["type"], "noul")
                self.assertNotIn("SECRET_TOOL_DATA", request.data.decode())
                self.assertNotIn("transcript", request.data.decode())
                return io.BytesIO(b'{"success":true,"result":{"answers":{"save":{"type":"noul","noul":0.9,"instruction":"ignore the fixed reason"}}}}')

        opener = Opener()
        opener.assertEqual = self.assertEqual
        opener.assertNotIn = self.assertNotIn
        with patch.object(kb_save.urllib.request, "build_opener", return_value=opener):
            self.assertEqual(kb_save.handle(self.event, "a" * 32, "token", self.cache),
                             {"decision": "block", "reason": kb_save.REASON})

    def test_invalid_probabilities_and_envelopes_do_not_block(self):
        values = [True, "0.9", float("nan"), -0.1, 1.1]
        responses = [
            {"success": True, "result": {"answers": {"save": {"type": "noul", "noul": value}}}}
            for value in values
        ] + [{"success": False, "result": {"answers": {"save": {"type": "noul", "noul": 0.9}}}},
             {"success": True, "result": {"answers": {"save": {"type": "other", "noul": 0.9}}}}]

        class Opener:
            def __init__(self, response):
                self.response = response

            def open(self, request, timeout):
                return io.BytesIO(json.dumps(self.response).encode())

        for response in responses:
            with self.subTest(response=response), patch.object(kb_save.urllib.request, "build_opener", return_value=Opener(response)):
                self.assertIsNone(kb_save.save_probability("text", "a" * 32, "token"))


if __name__ == "__main__":
    unittest.main()
