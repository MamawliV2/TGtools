#!/bin/bash

# نام فایل پایتون
PYTHON_FILE="tools.py"

# محتوای کد پایتون که در فایل قرار می‌گیرد
PYTHON_CODE=$(cat <<EOF
from telethon import TelegramClient, events
import asyncio
from datetime import datetime
import schedule

# دریافت اطلاعات حساب کاربری از کاربر
api_id = input("Please enter your API ID: ")
api_hash = input("Please enter your API Hash: ")
phone_number = input("Please enter your phone number: ")
channel_username = input("Please enter the default channel username (e.g., @channelusername): ")

# لیست آی‌دی‌های کاربران ادمین
admin_users = ['865122337', '@MmdOmidian']  # آی‌دی عددی و یوزرنیم شما

# ایجاد یک کلاینت تلگرام
client = TelegramClient('session_name', api_id, api_hash)

# متغیرهای کنترل
keep_alive_active = False
auto_reply_active = False
default_reply = "صبور باشید در اسرع وقت پاسخگو هستم."
auto_reply_count = 0
last_auto_reply_time = None
scheduled_messages = []

# تابعی برای بررسی اینکه آیا کاربر ادمین است یا خیر
def is_admin(user_id):
    """بررسی می‌کند که آیا کاربر جزو ادمین‌ها است یا خیر"""
    return str(user_id) in admin_users

async def keep_alive():
    """تابعی که پیام‌ها را به صورت خودکار ارسال می‌کند"""
    global keep_alive_active
    while keep_alive_active:
        await client.send_message(channel_username, 'Keeping the channel active')
        await asyncio.sleep(5)  # هر 5 ثانیه یکبار پیام ارسال می‌شود

# دستور .keepalive برای شروع ارسال پیام‌های خودکار
@client.on(events.NewMessage(pattern=r'\.keepalive'))
async def start_keep_alive(event):
    if not is_admin(event.sender_id):
        await event.reply("You are not authorized to use this command.")
        return

    global keep_alive_active
    if not keep_alive_active:
        keep_alive_active = True
        await event.reply("Keepalive started!")
        asyncio.create_task(keep_alive())
    else:
        await event.reply("Keepalive is already active.")

# دستور .stopalive برای توقف ارسال پیام‌های خودکار
@client.on(events.NewMessage(pattern=r'\.stopalive'))
async def stop_keep_alive(event):
    if not is_admin(event.sender_id):
        await event.reply("You are not authorized to use this command.")
        return

    global keep_alive_active
    if keep_alive_active:
        keep_alive_active = False
        await event.reply("Keepalive stopped!")
    else:
        await event.reply("Keepalive is not active.")

# دستور .startpish برای فعال کردن پاسخ خودکار
@client.on(events.NewMessage(pattern=r'\.startpish'))
async def start_auto_reply(event):
    if not is_admin(event.sender_id):
        await event.reply("You are not authorized to use this command.")
        return

    global auto_reply_active
    if not auto_reply_active:
        auto_reply_active = True
        await event.reply("Auto-reply started!")
    else:
        await event.reply("Auto-reply is already active.")

# دستور .stoppish برای غیرفعال کردن پاسخ خودکار
@client.on(events.NewMessage(pattern=r'\.stoppish'))
async def stop_auto_reply(event):
    if not is_admin(event.sender_id):
        await event.reply("You are not authorized to use this command.")
        return

    global auto_reply_active
    if auto_reply_active:
        auto_reply_active = False
        await event.reply("Auto-reply stopped!")
    else:
        await event.reply("Auto-reply is not active.")

# دستور .edit برای ویرایش پیام پیشفرض پاسخ خودکار
@client.on(events.NewMessage(pattern=r'\.edit (.+)'))
async def edit_auto_reply(event):
    if not is_admin(event.sender_id):
        await event.reply("You are not authorized to use this command.")
        return

    global default_reply
    new_reply = event.pattern_match.group(1)
    default_reply = new_reply
    await event.reply(f"Auto-reply message updated to: {default_reply}")

# دریافت پیام‌ها و ارسال پاسخ خودکار در صورت فعال بودن و پیام از چت خصوصی باشد
@client.on(events.NewMessage(incoming=True))
async def auto_reply(event):
    global auto_reply_active, default_reply, auto_reply_count, last_auto_reply_time
    # اگر پاسخ خودکار فعال بود و پیام دریافتی از یک چت خصوصی بود
    if auto_reply_active and event.is_private:
        await event.reply(default_reply)
        auto_reply_count += 1
        last_auto_reply_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# دستور .status برای نمایش وضعیت بات
@client.on(events.NewMessage(pattern=r'\.status'))
async def status(event):
    if not is_admin(event.sender_id):
        await event.reply("You are not authorized to use this command.")
        return

    global keep_alive_active, auto_reply_active, auto_reply_count, last_auto_reply_time
    status_message = (
        f"**Bot Status:**\n"
        f"Auto-reply: {'Active' if auto_reply_active else 'Inactive'}\n"
        f"Keepalive: {'Active' if keep_alive_active else 'Inactive'}\n"
        f"Auto-reply count: {auto_reply_count}\n"
        f"Last auto-reply time: {last_auto_reply_time if last_auto_reply_time else 'No replies yet'}"
    )
    await event.reply(status_message)

# دستور .schedule برای زمان‌بندی پیام
@client.on(events.NewMessage(pattern=r'\.schedule (.+) (.+) (.+)'))
async def schedule_message(event):
    if not is_admin(event.sender_id):
        await event.reply("You are not authorized to use this command.")
        return

    message_time = event.pattern_match.group(1)  # زمان پیام
    message_text = event.pattern_match.group(2)  # متن پیام
    recipient_id = event.pattern_match.group(3)  # آی‌دی فرد یا گروه

    scheduled_messages.append((message_time, message_text, recipient_id))
    await event.reply(f"Message scheduled to be sent at {message_time} to {recipient_id}: {message_text}")

def send_scheduled_messages():
    current_time = datetime.now().strftime("%H:%M")
    for message_time, message_text, recipient_id in scheduled_messages:
        if message_time == current_time:
            client.send_message(recipient_id, message_text)

schedule.every().minute.do(send_scheduled_messages)

async def main():
    # اتصال به حساب کاربری
    await client.start(phone=phone_number)
    print("Client Created and Online")

    # نگه داشتن کلاینت آنلاین و دریافت دستورات
    await client.run_until_disconnected()

# اجرای برنامه
client.loop.run_until_complete(main())
EOF
)

# ایجاد فایل پایتون و نوشتن کد داخل آن
echo "$PYTHON_CODE" > $PYTHON_FILE
echo "Python file '$PYTHON_FILE' has been created."

# اجرای فایل پایتون
python3 $PYTHON_FILE
