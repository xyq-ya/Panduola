import os

DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_USER = os.getenv('DB_USER', 'root')
DB_PASSWORD = os.getenv('DB_PASSWORD', 'yang20050219')  # change locally or use env var
DB_NAME = os.getenv('DB_NAME', 'task_management_system')
DB_CHARSET = os.getenv('DB_CHARSET', 'utf8mb4')


# Volcengine Ark specific defaults
# Use ARK_API_KEY for the Ark SDK (if provided) and ARK_BASE_URL to override default endpoint
ARK_API_KEY = os.getenv('ARK_API_KEY', '9368faf8-bb72-4feb-8769-6613654c0db6')
# Default base url used in the user's example; change per region if needed
ARK_BASE_URL = os.getenv('ARK_BASE_URL', 'https://ark.cn-beijing.volces.com/api/v3')
# Generic external AI endpoint/credentials fallback (used when Ark SDK not available)
AI_API_URL = os.getenv('AI_API_URL')
AI_API_KEY = os.getenv('AI_API_KEY')

