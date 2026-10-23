"""Tiny stand-in for the CoolerControl daemon API used by music-mode.

Prints its port on stdout, then serves until killed. Requires HTTP basic auth
"CCAdmin:secret" on /login and the session cookie everywhere else.
"""
import base64
import http.server
import json
import sys

MODES = [{"uid": "stock-uid", "name": "Stock"}, {"uid": "music-uid", "name": "Music"}]
state = {"current": "stock-uid"}


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def reply(self, code, body=None, headers=()):
        self.send_response(code)
        for key, value in headers:
            self.send_header(key, value)
        data = json.dumps(body).encode() if body is not None else b""
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def authed(self):
        return "session=ok" in self.headers.get("Cookie", "")

    def do_POST(self):
        if self.path == "/login":
            expected = "Basic " + base64.b64encode(b"CCAdmin:secret").decode()
            if self.headers.get("Authorization") != expected:
                return self.reply(401)
            return self.reply(200, None, [("Set-Cookie", "session=ok; Path=/")])
        if not self.authed():
            return self.reply(401)
        if self.path.startswith("/modes-active/"):
            uid = self.path.rsplit("/", 1)[1]
            if uid not in {m["uid"] for m in MODES}:
                return self.reply(404)
            state["current"] = uid
            return self.reply(200, {})
        self.reply(404)

    def do_GET(self):
        if not self.authed():
            return self.reply(401)
        if self.path == "/modes":
            return self.reply(200, {"modes": MODES})
        if self.path == "/modes-active":
            return self.reply(200, {"current_mode_uid": state["current"], "previous_mode_uid": None})
        self.reply(404)


server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
print(server.server_address[1], flush=True)
sys.stdout.close()
server.serve_forever()
