#!/bin/bash

# نصب کتابخانه‌های مورد نیاز
pip install python-telegram-bot requests

# ایجاد فایل chatbot.py
cat <<EOF > chatbot.py
from telegram import Update
from telegram.ext import Updater, CommandHandler, MessageHandler, filters
import requests

# تابعی برای ارسال پیام به CustomGPT API و دریافت پاسخ
def get_gpt_response(user_message):
    api_key = "5255|ihKZFL3qnqkQ3exoazzDHRLa7E3zcwjRoJOXFsjW0903d7c7"  # API Key شما
    url = "https://api.customgpt.ai/v1/chat"  # آدرس API CustomGPT
    headers = {
        "Authorization": f"Bearer {api_key}",  # اینجا API Key به درستی قرار گرفته است
        "Content-Type": "application/json"
    }
    data = {"prompt": user_message}
    response = requests.post(url, headers=headers, json=data)
    return response.json().get("response", "متاسفم، نمی‌توانم پاسخ بدهم.")

# مدیریت پیام‌های کاربران
def handle_message(update: Update, context):
    user_message = update.message.text
    response = get_gpt_response(user_message)
    update.message.reply_text(response)

def main():
    telegram_token = "7224760038:AAHeJWSCebzNbpAatbyYxw11xH7yb2WX6iM"  # API Token تلگرام شما
    updater = Updater(telegram_token, use_context=True)

    # مدیریت پیام‌ها
    dp = updater.dispatcher
    dp.add_handler(MessageHandler(Filters.text, handle_message))

    # شروع ربات
    updater.start_polling()
    updater.idle()

if __name__ == '__main__':
    main()
EOF

# اجرای فایل chatbot.py
python3 chatbot.py
