# Credentials Setup

This project declares credential references only. Secret values must be added
manually by an authorized human outside version control.

## Declared References

- env:KOMANDESK_SERVICE_TOKEN: Komandesk service API

## Safe Setup Options

1. Preferred: store the value in your team's password manager, vault or runtime
   environment and keep only the reference in Git.
2. Local fallback: copy `.komandesk/secrets.local.env.example` to
   `.komandesk/secrets.local.env`, paste the value manually, and never commit
   that file.

## Agent Rules

- Do not ask the user to paste secret values into chat.
- Do not read `.komandesk/secrets.local.env`.
- Do not print secrets.
- If a secret is missing, update Komandesk with a clear blocker.
