import os
import sys

def main():
    try:
        from volcenginesdkarkruntime import Ark
    except Exception as e:
        print('Ark SDK import failed:', e)
        sys.exit(2)

    api_key = os.environ.get('ARK_API_KEY')
    if not api_key:
        print('ARK_API_KEY not set in environment')
        sys.exit(2)

    client = Ark(
        base_url=os.environ.get('ARK_BASE_URL', 'https://ark.cn-beijing.volces.com/api/v3'),
        api_key=api_key,
    )

    try:
        print('----- standard request -----')
        completion = client.chat.completions.create(
            model='deepseek-v3-1-terminus',
            messages=[
                {'role': 'system', 'content': '你是人工智能助手.'},
                {'role': 'user', 'content': '你好'},
            ],
        )
        # Attempt to print the content safely
        try:
            print(completion.choices[0].message.content)
        except Exception:
            print('Standard request returned:', completion)

        print('\n----- streaming request -----')
        stream = client.chat.completions.create(
            model='deepseek-v3-1-terminus',
            messages=[
                {'role': 'system', 'content': '你是人工智能助手.'},
                {'role': 'user', 'content': '你好'},
            ],
            stream=True,
        )

        for chunk in stream:
            if not getattr(chunk, 'choices', None):
                continue
            try:
                delta = chunk.choices[0].delta
                # delta.content may be present
                print(getattr(delta, 'content', ''), end='')
            except Exception:
                print(chunk, end='')
        print()  # newline after streaming

    except Exception as e:
        print('Request error:', e)
        sys.exit(1)

if __name__ == '__main__':
    main()
