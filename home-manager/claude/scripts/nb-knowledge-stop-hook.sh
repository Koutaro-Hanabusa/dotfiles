#!/usr/bin/env bash
# Stop hook: no-op.
#
# Previously emitted `{decision: block, reason: ...}` to remind Claude to record
# nb-knowledge before stopping. Side effect: Claude's "stop を許可します" style
# acknowledgement text leaked into subsequent `git commit -m` HEREDOCs, polluting
# commit history. Disabled — the nb-knowledge skill's own trigger description is
# sufficient to invoke it during the turn.
exit 0
