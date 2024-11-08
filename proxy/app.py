from flask import Flask, request, jsonify
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_cors import CORS
from openai import OpenAI
import os
from dotenv import load_dotenv
import redis
import uuid
import time

load_dotenv()

app = Flask(__name__)
CORS(app)

# Redis setup for rate limiting
redis_client = redis.from_url(os.getenv('REDIS_URL', 'redis://localhost:6379'))

# OpenAI client setup
client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

# Rate limiter setup
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["5 per minute", "100 per day"]
)

# Store valid game tokens
VALID_TOKENS = {}

def validate_token(token):
    """Validate the game token"""
    if token not in VALID_TOKENS:
        return False
    return True

@app.route('/generate-token', methods=['POST'])
@limiter.limit("3 per day")  # Limit token generation
def generate_token():
    """Generate a new game token"""
    new_token = str(uuid.uuid4())
    VALID_TOKENS[new_token] = {
        'created_at': time.time(),
        'requests_made': 0
    }
    return jsonify({'token': new_token})

@app.route('/chat', methods=['POST'])
@limiter.limit("30 per minute")
def chat():
    """Handle chat requests with rate limiting and auth"""
    # Get the auth token from headers
    auth_token = request.headers.get('X-Game-Token')
    if not auth_token or not validate_token(auth_token):
        return jsonify({'error': 'Invalid or missing token'}), 401

    # Get the message from request
    message = request.json.get('message')
    if not message:
        return jsonify({'error': 'No message provided'}), 400

    try:
        # Track request for this token
        VALID_TOKENS[auth_token]['requests_made'] += 1

        # Make OpenAI API call
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": message}],
            max_tokens=150  # Limit response length
        )
        
        return jsonify({
            'response': response.choices[0].message.content,
            'requests_remaining': 100 - VALID_TOKENS[auth_token]['requests_made']
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', 8000)))