"""Generate config.json from Railway environment variables.

Maps environment variables to the config.json fields expected by src/config.py.
Run this script before starting the application on Railway.
"""

import json
import os


def env(key, default=""):
    return os.environ.get(key, default)


def env_bool(key, default=False):
    val = os.environ.get(key, "")
    if val == "":
        return default
    return val.lower() in ("true", "1", "yes")


def env_int(key, default=0):
    val = os.environ.get(key, "")
    if val == "":
        return default
    return int(val)


config = {
    "verbose": env_bool("MPV2_VERBOSE", True),
    "firefox_profile": env("MPV2_FIREFOX_PROFILE", ""),
    "headless": env_bool("MPV2_HEADLESS", True),
    "ollama_base_url": env("MPV2_OLLAMA_BASE_URL", "http://127.0.0.1:11434"),
    "ollama_model": env("OLLAMA_MODEL", "llama3.2:3b"),
    "twitter_language": env("MPV2_TWITTER_LANGUAGE", "English"),
    "nanobanana2_api_base_url": env(
        "MPV2_NANOBANANA2_API_BASE_URL",
        "https://generativelanguage.googleapis.com/v1beta",
    ),
    "nanobanana2_api_key": env("MPV2_NANOBANANA2_API_KEY"),
    "nanobanana2_model": env("MPV2_NANOBANANA2_MODEL", "gemini-3.1-flash-image-preview"),
    "nanobanana2_aspect_ratio": env("MPV2_NANOBANANA2_ASPECT_RATIO", "9:16"),
    "threads": env_int("MPV2_THREADS", 2),
    "zip_url": env("MPV2_ZIP_URL"),
    "is_for_kids": env_bool("MPV2_IS_FOR_KIDS", False),
    "google_maps_scraper": env(
        "MPV2_GOOGLE_MAPS_SCRAPER",
        "https://github.com/gosom/google-maps-scraper/archive/refs/tags/v0.9.7.zip",
    ),
    "email": {
        "smtp_server": env("MPV2_EMAIL_SMTP_SERVER", "smtp.gmail.com"),
        "smtp_port": env_int("MPV2_EMAIL_SMTP_PORT", 587),
        "username": env("MPV2_EMAIL_USERNAME"),
        "password": env("MPV2_EMAIL_PASSWORD"),
    },
    "google_maps_scraper_niche": env("MPV2_GOOGLE_MAPS_SCRAPER_NICHE"),
    "scraper_timeout": env_int("MPV2_SCRAPER_TIMEOUT", 300),
    "outreach_message_subject": env("MPV2_OUTREACH_MESSAGE_SUBJECT", "I have a question..."),
    "outreach_message_body_file": env("MPV2_OUTREACH_MESSAGE_BODY_FILE", "outreach_message.html"),
    "stt_provider": env("MPV2_STT_PROVIDER", "local_whisper"),
    "whisper_model": env("MPV2_WHISPER_MODEL", "base"),
    "whisper_device": env("MPV2_WHISPER_DEVICE", "auto"),
    "whisper_compute_type": env("MPV2_WHISPER_COMPUTE_TYPE", "int8"),
    "assembly_ai_api_key": env("MPV2_ASSEMBLY_AI_API_KEY"),
    "tts_voice": env("MPV2_TTS_VOICE", "Jasper"),
    "font": env("MPV2_FONT", "bold_font.ttf"),
    "imagemagick_path": env("MPV2_IMAGEMAGICK_PATH", "/usr/bin/convert"),
    "script_sentence_length": env_int("MPV2_SCRIPT_SENTENCE_LENGTH", 4),
}

config_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "config.json")

with open(config_path, "w") as f:
    json.dump(config, f, indent=2)

print(f"[generate_config] config.json written to {config_path}")
