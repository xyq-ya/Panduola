import os
from flask import current_app

# Try to use the official Volcengine Ark runtime SDK if available; otherwise fall back
# to a simple requests-based POST. This keeps the code flexible in dev environments
# where the SDK may not be installed.
try:
    from volcenginesdkarkruntime import Ark  # type: ignore
    _HAS_ARK = True
except Exception:
    _HAS_ARK = False

try:
    import requests
    _HAS_REQUESTS = True
except Exception:
    _HAS_REQUESTS = False


def _parse_choice_like(obj):
    """Try to extract text content from OpenAI/Ark-like choices structure."""
    try:
        choices = obj.get('choices') if isinstance(obj, dict) else getattr(obj, 'choices', None)
        if not choices:
            return None
        first = choices[0]
        # message.content path
        msg = first.get('message') if isinstance(first, dict) else getattr(first, 'message', None)
        if msg:
            content = msg.get('content') if isinstance(msg, dict) else getattr(msg, 'content', None)
            if content:
                return content
        # fallback to text
        text = first.get('text') if isinstance(first, dict) else getattr(first, 'text', None)
        if text:
            return text
    except Exception:
        pass
    return None


def analyze_text(text: str = None, model: str = None, messages: list = None, stream: bool = False) -> dict:
    """Analyze `text` via Volcengine Ark SDK or via a generic HTTP AI endpoint.

    Accepts either a plain `text` string or a `messages` list (OpenAI-style).
    Returns a dict containing at least one of:
      - {"analysis": <string>, "provider": <str>, ...}
      - {"error": <msg>}
    """
    # Prefer Ark-specific env/config
    ark_key = current_app.config.get('ARK_API_KEY') or os.getenv('ARK_API_KEY') or current_app.config.get('AI_API_KEY')
    ark_base = current_app.config.get('ARK_BASE_URL') or os.getenv('ARK_BASE_URL') or current_app.config.get('AI_API_URL')
    ark_model = model or os.getenv('ARK_MODEL') or current_app.config.get('ARK_MODEL') or 'deepseek-v3-1-terminus'

    # Debug logging
    try:
        current_app.logger.info('ai_client.analyze_text: _HAS_ARK=%s, has_ark_key=%s, ark_base=%s, ark_model=%s', _HAS_ARK, bool(ark_key), bool(ark_base), ark_model)
    except Exception:
        try:
            print('ai_client.analyze_text:', {'_HAS_ARK': _HAS_ARK, 'has_ark_key': bool(ark_key), 'ark_base': bool(ark_base), 'ark_model': ark_model})
        except Exception:
            pass

    # 1) Try Ark SDK path
    if _HAS_ARK and ark_key:
        try:
            client = Ark(base_url=ark_base, api_key=ark_key) if ark_base else Ark(api_key=ark_key)

            if messages and isinstance(messages, list):
                send_messages = messages
            else:
                send_messages = [
                    {"role": "system", "content": "你是人工智能助手."},
                    {"role": "user", "content": text or ''},
                ]

            completion = client.chat.completions.create(
                model=ark_model,
                messages=send_messages,
                extra_headers={"x-is-encrypted": "true"},
                stream=stream,
            )

            # Try to normalize SDK response
            parsed = None
            try:
                # SDK object may be dict-like or object-like
                if isinstance(completion, dict):
                    parsed = _parse_choice_like(completion)
                else:
                    # try converting to dict if possible
                    try:
                        completion_dict = dict(completion)
                        parsed = _parse_choice_like(completion_dict)
                    except Exception:
                        parsed = None
            except Exception:
                parsed = None

            if not parsed:
                # try attribute-based extraction
                try:
                    choices = getattr(completion, 'choices', None)
                    if choices:
                        first = choices[0]
                        msg = getattr(first, 'message', None)
                        if msg:
                            parsed = getattr(msg, 'content', None)
                        else:
                            parsed = getattr(first, 'text', None)
                except Exception:
                    parsed = None

            if parsed:
                return {"analysis": parsed, "provider": "ark"}
            return {"error": "Ark returned no readable content"}
        except Exception as e:
            return {"error": f"Ark SDK call failed: {e}"}

    # 2) Generic HTTP fallback
    ai_url = current_app.config.get('AI_API_URL') or os.getenv('AI_API_URL')
    ai_key = current_app.config.get('AI_API_KEY') or os.getenv('AI_API_KEY')
    if _HAS_REQUESTS and ai_url and ai_key:
        headers = {'Authorization': f'Bearer {ai_key}', 'Content-Type': 'application/json'}
        # Build payload: prefer OpenAI-like structure when messages provided
        if messages and isinstance(messages, list):
            payload = {'model': model or ark_model, 'messages': messages}
        else:
            # Some generic endpoints accept 'text', others expect OpenAI-like shape.
            # Send both to maximize compatibility.
            payload = {'text': text or '', 'model': model or ark_model}

        try:
            resp = requests.post(ai_url, json=payload, headers=headers, timeout=15)
            resp.raise_for_status()
            j = resp.json()
            # Try to parse OpenAI-like choices
            content = _parse_choice_like(j)
            if not content and isinstance(j, dict):
                # maybe provider returns {'analysis': ...}
                content = j.get('analysis') or j.get('summary') or None

            if content:
                return {"analysis": content, "provider": "http" , "raw": j}
            # fallback: if response is a string or has usable data, stringify
            if isinstance(j, str):
                return {"analysis": j, "provider": "http", "raw": j}
            # try to find any top-level text-like field
            for k in ('result', 'data', 'output'):
                if isinstance(j.get(k), str):
                    return {"analysis": j.get(k), "provider": "http", "raw": j}

            # as last resort, return whole json as string
            return {"analysis": str(j), "provider": "http", "raw": j}
        except Exception as e:
            return {"error": str(e)}

    return {"error": "no AI configuration or required packages (ark sdk / requests) not installed"}
