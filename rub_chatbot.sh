#!/bin/bash

# نصب کتابخانه‌های مورد نیاز
pip install python-telegram-bot --upgrade
pip install requests

# ایجاد فایل chatbot.py
cat <<EOF > chatbot.py
from telegram import Update, ForceReply
from telegram.ext import Application, CommandHandler, MessageHandler, filters
import requests

# تابعی برای ارسال پیام به CustomGPT API و دریافت پاسخ
def get_gpt_response(user_message):
    api_key = "5255|ihKZFL3qnqkQ3exoazzDHRLa7E3zcwjRoJOXFsjW0903d7c7"  # API Key شما
    url = "https://api.customgpt.ai/v1/chat"  # آدرس API CustomGPT
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    data = {"prompt": user_message}
    response = requests.post(url, headers=headers, json=data)
    return response.json().get("response", "متاسفم، نمی‌توانم پاسخ بدهم.")

# مدیریت پیام‌های کاربران
async def handle_message(update: Update, context):
    user_message = update.message.text
    response = get_gpt_response(user_message)
    await update.message.reply_text(response)

async def start(update: Update, context):
    """Sends a message when the command /start is issued."""
    user = update.effective_user
    await update.message.reply_html(
        rf"سلام {user.mention_html()}!",
        reply_markup=ForceReply(selective=True),
    )

def main():
    telegram_token = "YOUR_TELEGRAM_API_TOKEN"  # API Token تلگرام شما
    application = Application.builder().token(telegram_token).build()

    # مدیریت پیام‌ها
    application.add_handler(CommandHandler("start", start))
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))

    # شروع ربات
    application.run_polling()

if __name__ == '__main__':
    main()
EOF

# اجرای فایل chatbot.py
python3 chatbot.py
