import telebot
import requests

# توکن ربات تلگرام خود را اینجا جایگزین کنید
TELEGRAM_BOT_TOKEN = '8067037768:AAGaYvrPy-SbjsJJ8xcSYozQhvErswrgt9U'
# آدرس API سایت aitext.chat را اینجا جایگزین کنید
AITEXT_API_URL = 'https://api.aitext.chat/v1/message'

bot = telebot.TeleBot(TELEGRAM_BOT_TOKEN)

@bot.message_handler(func=lambda message: True)
def handle_message(message):
    user_input = message.text
    response = get_aitext_response(user_input)
    bot.send_message(message.chat.id, response)

def get_aitext_response(user_input):
    headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer xEm3SMNhgUWpSs+SRxgSHg=='
    }
    data = {
        'input': user_input
    }
    response = requests.post(AITEXT_API_URL, headers=headers, json=data)
    if response.status_code == 200:
        return response.json()['output']
    else:
        return "Error: Unable to get response from AI."

if __name__ == "__main__":
    bot.polling()
