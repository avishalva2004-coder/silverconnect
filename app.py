from flask import Flask, render_template, request, redirect, url_for, session, jsonify, g
from flask_bcrypt import Bcrypt
from flask_cors import CORS
import pymysql
import os
import random
import re
import uuid
import json

app = Flask(__name__)

TRANSLATIONS_DIR = os.path.join(os.path.dirname(__file__), 'translations')
_translation_cache = {}

def load_translations(lang):
    if lang in _translation_cache:
        return _translation_cache[lang]
    path = os.path.join(TRANSLATIONS_DIR, f'{lang}.json')
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        _translation_cache[lang] = data
        return data
    if lang != 'en':
        return load_translations('en')
    return {}

def get_available_languages():
    langs = []
    for f in sorted(os.listdir(TRANSLATIONS_DIR)):
        if f.endswith('.json'):
            path = os.path.join(TRANSLATIONS_DIR, f)
            with open(path, 'r', encoding='utf-8') as fh:
                data = json.load(fh)
            meta = data.get('__meta__', {})
            langs.append({
                'code': f[:-5],
                'name': meta.get('name', f[:-5]),
                'native': meta.get('native', f[:-5]),
                'flag': meta.get('flag', '')
            })
    return langs
app.secret_key = os.environ.get('SECRET_KEY', os.urandom(24).hex())
app.config['UPLOAD_FOLDER'] = os.path.join(os.path.dirname(__file__), 'static', 'uploads')
app.config['MAX_CONTENT_LENGTH'] = 5 * 1024 * 1024
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'webp'}
bcrypt = Bcrypt(app)
CORS(app)

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

DB_CONFIG = {
    'host': os.environ.get('DB_HOST', 'localhost'),
    'user': os.environ.get('DB_USER', 'root'),
    'password': os.environ.get('DB_PASSWORD', ''),
    'database': os.environ.get('DB_NAME', 'silverconnect'),
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor
}

def get_db():
    return pymysql.connect(**DB_CONFIG)

def login_required(f):
    def wrapper(*args, **kwargs):
        if 'user_id' not in session:
            return redirect(url_for('index'))
        return f(*args, **kwargs)
    wrapper.__name__ = f.__name__
    return wrapper

app.jinja_env.globals.update(enumerate=enumerate, str=str, int=int, len=len)

@app.before_request
def before_request():
    lang = request.args.get('lang') or session.get('lang') or 'en'
    if lang not in [l['code'] for l in get_available_languages()]:
        lang = 'en'
    g.lang = lang
    translations = load_translations(lang)
    g.translations = translations
    g.available_languages = get_available_languages()

def translate(text):
    return g.translations.get(text, text) if hasattr(g, 'translations') else text

app.jinja_env.globals.update(_=translate, available_languages=get_available_languages)

# ─── Language Switch ───

@app.route('/lang/<lang>')
def set_language(lang):
    if lang in [l['code'] for l in get_available_languages()]:
        session['lang'] = lang
        if 'user_id' in session:
            db = get_db()
            cur = db.cursor()
            cur.execute('UPDATE users SET language = %s WHERE id = %s', (lang, session['user_id']))
            db.commit()
            cur.close()
            db.close()
    return redirect(request.referrer or url_for('index'))

# ─── Auth Routes ───

@app.route('/')
def index():
    if 'user_id' in session:
        return redirect(url_for('home'))
    return render_template('splash.html')

@app.route('/login')
def login_page():
    if 'user_id' in session:
        return redirect(url_for('home'))
    user = request.args.get('created')
    return render_template('login.html', just_created=user)

@app.route('/signup_page')
def signup_page():
    return render_template('signup.html')

@app.route('/signup', methods=['POST'])
def signup():
    name = request.form.get('name', '').strip()
    email = request.form.get('email', '').strip().lower()
    password = request.form.get('password', '').strip()
    if not name or not email or not password:
        return render_template('signup.html', error='All fields are required.')
    if re.search(r'\d', name):
        return render_template('signup.html', error='Name cannot contain numbers.')
    if '@' not in email:
        return render_template('signup.html', error='Email must contain @.')
    if len(password) < 8:
        return render_template('signup.html', error='Password must be at least 8 characters.')
    if not re.search(r'[A-Z]', password):
        return render_template('signup.html', error='Password needs an uppercase letter.')
    if not re.search(r'[a-z]', password):
        return render_template('signup.html', error='Password needs a lowercase letter.')
    if not re.search(r'\d', password):
        return render_template('signup.html', error='Password needs a number.')
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT id FROM users WHERE email = %s', (email,))
    if cur.fetchone():
        cur.close()
        db.close()
        return render_template('signup.html', error='Email already registered.')
    pw_hash = bcrypt.generate_password_hash(password).decode('utf-8')
    avatar = name.strip()[0].upper()
    cur.execute('INSERT INTO users (name, email, password_hash, avatar, status, language) VALUES (%s, %s, %s, %s, %s, %s)',
                (name, email, pw_hash, avatar, 'online', session.get('lang', 'en')))
    db.commit()
    user_id = cur.lastrowid
    cur.close()
    db.close()
    session['user_id'] = user_id
    session['user_name'] = name
    session['user_avatar'] = avatar
    return redirect(url_for('home'))

@app.route('/login', methods=['POST'])
def login():
    email = request.form.get('email', '').strip().lower()
    password = request.form.get('password', '').strip()
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT * FROM users WHERE email = %s', (email,))
    user = cur.fetchone()
    cur.close()
    db.close()
    if user and bcrypt.check_password_hash(user['password_hash'], password):
        session['user_id'] = user['id']
        session['user_name'] = user['name']
        session['user_avatar'] = user['avatar']
        session['lang'] = user.get('language', 'en')
        db2 = get_db()
        cur2 = db2.cursor()
        cur2.execute('UPDATE users SET status = %s WHERE id = %s', ('online', user['id']))
        db2.commit()
        cur2.close()
        db2.close()
        return redirect(url_for('home'))
    return render_template('login.html', error='Invalid email or password.')

@app.route('/logout')
def logout():
    uid = session.get('user_id')
    if uid:
        db = get_db()
        cur = db.cursor()
        cur.execute('UPDATE users SET status = %s WHERE id = %s', ('offline', uid))
        db.commit()
        cur.close()
        db.close()
    session.clear()
    return redirect(url_for('index'))

# ─── Main Pages ───

@app.route('/home')
@login_required
def home():
    uid = session['user_id']
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT COUNT(*) AS cnt FROM user_groups WHERE user_id = %s', (uid,))
    group_count = cur.fetchone()['cnt']
    cur.execute('SELECT COUNT(*) AS cnt FROM medicines WHERE user_id = %s AND taken = FALSE', (uid,))
    med_count = cur.fetchone()['cnt']
    cur.execute('SELECT * FROM medicines WHERE user_id = %s AND taken = FALSE ORDER BY med_time LIMIT 5', (uid,))
    today_meds = cur.fetchall()
    cur.execute('SELECT * FROM health_tips ORDER BY RAND() LIMIT 1')
    tip = cur.fetchone()
    cur.execute('''SELECT COUNT(*) AS cnt FROM friendships
                   WHERE ((user_id1 = %s OR user_id2 = %s) AND status = 'accepted')''', (uid, uid))
    friend_count = cur.fetchone()['cnt']
    cur.close()
    db.close()
    quotes = g.translations.get('__quotes__', [])
    if not quotes:
        quotes = ["The best time to plant a tree was 20 years ago. The second best time is now."]
    quote = random.choice(quotes)
    return render_template('home.html', group_count=group_count, med_count=med_count,
                           today_meds=today_meds, tip=tip, friend_count=friend_count, quote=quote)

@app.route('/communities')
@login_required
def communities():
    uid = session['user_id']
    db = get_db()
    cur = db.cursor()
    cur.execute('''SELECT g.* FROM groups_tb g''')
    groups = cur.fetchall()
    cur.execute('SELECT group_id FROM user_groups WHERE user_id = %s', (uid,))
    joined = {r['group_id'] for r in cur.fetchall()}

    # Friend requests pending for me
    cur.execute('''SELECT f.requester_id AS id, u.name, u.avatar FROM friendships f
                   JOIN users u ON u.id = f.requester_id
                   WHERE f.status = 'pending'
                     AND ((f.requester_id = f.user_id1 AND f.user_id2 = %s)
                       OR (f.requester_id = f.user_id2 AND f.user_id1 = %s))''', (uid, uid))
    pending_requests = cur.fetchall()

    # My friends (accepted)
    cur.execute("""SELECT u.id, u.name, u.avatar, u.status FROM friendships f
                   JOIN users u ON u.id = CASE WHEN f.user_id1 = %s THEN f.user_id2 ELSE f.user_id1 END
                   WHERE (f.user_id1 = %s OR f.user_id2 = %s) AND f.status = 'accepted'""", (uid, uid, uid))
    my_friends = cur.fetchall()
    friend_ids = {f['id'] for f in my_friends}

    # Suggested users — not me, not friends, not pending
    cur.execute('''SELECT user_id1, user_id2 FROM friendships
                   WHERE (user_id1 = %s OR user_id2 = %s) AND status = 'pending' ''', (uid, uid))
    pending_ids = set()
    for r in cur.fetchall():
        pending_ids.add(r['user_id1'])
        pending_ids.add(r['user_id2'])
    excluded = {uid} | friend_ids | pending_ids
    if excluded:
        placeholders = ','.join(['%s'] * len(excluded))
        cur.execute(f'SELECT id, name, avatar FROM users WHERE id NOT IN ({placeholders}) LIMIT 10', tuple(excluded))
    else:
        cur.execute('SELECT id, name, avatar FROM users WHERE id != %s LIMIT 10', (uid,))
    suggested = cur.fetchall()

    cur.close()
    db.close()
    return render_template('communities.html', groups=groups, joined=joined,
                           pending_requests=pending_requests, my_friends=my_friends, suggested=suggested)

@app.route('/community/join/<int:group_id>', methods=['POST'])
@login_required
def join_group(group_id):
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT id FROM groups_tb WHERE id = %s', (group_id,))
    if not cur.fetchone():
        cur.close(); db.close()
        return jsonify({'error': 'Group not found'}), 404
    cur.execute('INSERT IGNORE INTO user_groups (user_id, group_id) VALUES (%s, %s)',
                (session['user_id'], group_id))
    db.commit()
    cur.close(); db.close()
    return jsonify({'success': True})

@app.route('/group/<int:group_id>/chat')
@login_required
def group_chat(group_id):
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT * FROM groups_tb WHERE id = %s', (group_id,))
    group = cur.fetchone()
    if not group:
        cur.close(); db.close()
        return 'Group not found', 404
    cur.execute('''SELECT gm.*, u.name, u.avatar FROM group_messages gm
                   JOIN users u ON u.id = gm.user_id
                   WHERE gm.group_id = %s
                   ORDER BY gm.id ASC LIMIT 100''', (group_id,))
    messages = cur.fetchall()
    cur.execute('SELECT COUNT(*) AS cnt FROM group_messages WHERE group_id = %s', (group_id,))
    msg_count = cur.fetchone()['cnt']
    cur.close(); db.close()
    return render_template('group_chat.html', group=group, messages=messages, msg_count=msg_count)

@app.route('/group/<int:group_id>/send', methods=['POST'])
@login_required
def group_send(group_id):
    content = request.form.get('content', '').strip()
    image_url = None
    if 'image' in request.files:
        file = request.files['image']
        if file and file.filename and allowed_file(file.filename):
            ext = file.filename.rsplit('.', 1)[1].lower()
            fname = str(uuid.uuid4()) + '.' + ext
            path = os.path.join(app.config['UPLOAD_FOLDER'], fname)
            file.save(path)
            image_url = '/static/uploads/' + fname
    if not content and not image_url:
        return jsonify({'error': 'Empty message'}), 400
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT 1 FROM user_groups WHERE user_id = %s AND group_id = %s', (session['user_id'], group_id))
    if not cur.fetchone():
        cur.close(); db.close()
        return jsonify({'error': 'Not a member'}), 403
    cur.execute('INSERT INTO group_messages (group_id, user_id, content, image_url) VALUES (%s, %s, %s, %s)',
                (group_id, session['user_id'], content, image_url))
    db.commit()
    cur.close(); db.close()
    return jsonify({'success': True})

@app.route('/api/group/<int:group_id>/messages')
@login_required
def group_get_messages(group_id):
    last_id = request.args.get('after', 0, type=int)
    db = get_db()
    cur = db.cursor()
    cur.execute('''SELECT gm.*, u.name, u.avatar FROM group_messages gm
                   JOIN users u ON u.id = gm.user_id
                   WHERE gm.group_id = %s AND gm.id > %s
                   ORDER BY gm.id ASC''', (group_id, last_id))
    msgs = cur.fetchall()
    cur.close(); db.close()
    return jsonify(msgs)

@app.route('/chat')
@login_required
def chat():
    uid = session['user_id']
    db = get_db()
    cur = db.cursor()
    cur.execute('''SELECT DISTINCT m.room,
                   (SELECT content FROM messages WHERE room = m.room ORDER BY id DESC LIMIT 1) AS last_msg,
                   (SELECT COUNT(*) FROM messages WHERE room = m.room AND user_id != %s) AS msg_count
                   FROM messages m
                   WHERE m.room LIKE %s
                   ORDER BY (SELECT MAX(id) FROM messages WHERE room = m.room) DESC''',
                (uid, f'%{uid}%'))
    rooms_data = cur.fetchall()
    for r in rooms_data:
        parts = r['room'].split('_')
        partner_id = str(uid)
        for p in parts:
            if p != str(uid):
                partner_id = p
                break
        cur.execute('SELECT name, avatar, status FROM users WHERE id = %s', (partner_id,))
        partner = cur.fetchone() or {'name': 'Unknown', 'avatar': '?', 'status': 'offline'}
        r['name'] = partner['name']
        r['avatar'] = partner['avatar']
        r['status'] = partner['status']

    # Only show friends as chat-able contacts
    cur.execute("""SELECT DISTINCT u.id, u.name, u.avatar, u.status FROM friendships f
                   JOIN users u ON u.id = CASE WHEN f.user_id1 = %s THEN f.user_id2 ELSE f.user_id1 END
                   WHERE (f.user_id1 = %s OR f.user_id2 = %s) AND f.status = 'accepted'""", (uid, uid, uid))
    friends = cur.fetchall()
    existing_rooms = {r['room'] for r in rooms_data}
    friends = [f for f in friends if '_'.join(sorted([str(uid), str(f['id'])])) not in existing_rooms]

    cur.close(); db.close()
    return render_template('chat.html', rooms=rooms_data, friends=friends, session_user_id=uid)

@app.route('/chat/<room_name>')
@login_required
def chat_room(room_name):
    db = get_db()
    cur = db.cursor()
    cur.execute('''SELECT m.*, u.name, u.avatar FROM messages m
                   JOIN users u ON u.id = m.user_id
                   WHERE m.room = %s
                   ORDER BY m.id ASC LIMIT 100''', (room_name,))
    messages = cur.fetchall()
    cur.close(); db.close()
    # Figure out partner name
    parts = room_name.split('_')
    partner_id = str(session['user_id'])
    for p in parts:
        if p != partner_id:
            partner_id = p
            break
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT id, name, avatar FROM users WHERE id = %s', (partner_id,))
    partner = cur.fetchone() or {'id': partner_id, 'name': 'Friend', 'avatar': 'F'}
    cur.close(); db.close()
    return render_template('chat_room.html', room=room_name, messages=messages, partner=partner)

@app.route('/chat/<room_name>/send', methods=['POST'])
@login_required
def send_message(room_name):
    content = request.form.get('content', '').strip()
    image_url = None
    if 'image' in request.files:
        file = request.files['image']
        if file and file.filename and allowed_file(file.filename):
            ext = file.filename.rsplit('.', 1)[1].lower()
            fname = str(uuid.uuid4()) + '.' + ext
            path = os.path.join(app.config['UPLOAD_FOLDER'], fname)
            file.save(path)
            image_url = '/static/uploads/' + fname
    if not content and not image_url:
        return jsonify({'error': 'Empty message'}), 400
    db = get_db()
    cur = db.cursor()
    cur.execute('INSERT INTO messages (user_id, content, room, image_url) VALUES (%s, %s, %s, %s)',
                (session['user_id'], content, room_name, image_url))
    db.commit()
    cur.close(); db.close()
    return jsonify({'success': True, 'image_url': image_url})

@app.route('/api/chat/<room_name>/messages')
@login_required
def get_messages(room_name):
    last_id = request.args.get('after', 0, type=int)
    db = get_db()
    cur = db.cursor()
    cur.execute('''SELECT m.*, u.name, u.avatar FROM messages m
                   JOIN users u ON u.id = m.user_id
                   WHERE m.room = %s AND m.id > %s
                   ORDER BY m.id ASC''', (room_name, last_id))
    msgs = cur.fetchall()
    cur.close(); db.close()
    return jsonify(msgs)

@app.route('/api/user/<int:user_id>/status')
@login_required
def user_status(user_id):
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT status FROM users WHERE id = %s', (user_id,))
    u = cur.fetchone()
    cur.close(); db.close()
    return jsonify({'status': u['status'] if u else 'offline'})

@app.route('/chat/start/<int:user_id>')
@login_required
def start_chat(user_id):
    ids = sorted([session['user_id'], user_id])
    room = f'{ids[0]}_{ids[1]}'
    return redirect(url_for('chat_room', room_name=room))

@app.route('/events')
@login_required
def events():
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT * FROM events ORDER BY event_date ASC')
    events = cur.fetchall()
    cur.execute('SELECT event_id FROM event_rsvps WHERE user_id = %s', (session['user_id'],))
    rsvped = {r['event_id'] for r in cur.fetchall()}
    cur.close(); db.close()
    return render_template('events.html', events=events, rsvped=rsvped)

@app.route('/events/rsvp/<int:event_id>', methods=['POST'])
@login_required
def rsvp_event(event_id):
    db = get_db()
    cur = db.cursor()
    cur.execute('INSERT IGNORE INTO event_rsvps (user_id, event_id) VALUES (%s, %s)',
                (session['user_id'], event_id))
    cur.execute('UPDATE events SET going_count = (SELECT COUNT(*) FROM event_rsvps WHERE event_id = %s) WHERE id = %s',
                (event_id, event_id))
    db.commit()
    cur.close(); db.close()
    return jsonify({'success': True})

@app.route('/health')
@login_required
def health():
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT * FROM health_tips')
    tips = cur.fetchall()
    cur.execute('SELECT * FROM medicines WHERE user_id = %s ORDER BY med_time', (session['user_id'],))
    meds = cur.fetchall()
    cur.close(); db.close()
    return render_template('health.html', tips=tips, meds=meds)

@app.route('/medicine/add', methods=['POST'])
@login_required
def add_medicine():
    name = request.form.get('name', '').strip()
    dosage = request.form.get('dosage', '').strip()
    med_time = request.form.get('med_time', '08:00')
    food = request.form.get('food', 'After breakfast')
    if not name or not dosage:
        return jsonify({'error': 'Missing fields'}), 400
    db = get_db()
    cur = db.cursor()
    cur.execute('INSERT INTO medicines (user_id, name, dosage, med_time, food) VALUES (%s, %s, %s, %s, %s)',
                (session['user_id'], name, dosage, med_time, food))
    db.commit()
    cur.close(); db.close()
    return redirect(url_for('health'))

@app.route('/medicine/toggle/<int:med_id>', methods=['POST'])
@login_required
def toggle_medicine(med_id):
    db = get_db()
    cur = db.cursor()
    cur.execute('UPDATE medicines SET taken = NOT taken WHERE id = %s AND user_id = %s',
                (med_id, session['user_id']))
    db.commit()
    cur.close(); db.close()
    return jsonify({'success': True})

@app.route('/medicine/delete/<int:med_id>', methods=['POST'])
@login_required
def delete_medicine(med_id):
    db = get_db()
    cur = db.cursor()
    cur.execute('DELETE FROM medicines WHERE id = %s AND user_id = %s', (med_id, session['user_id']))
    db.commit()
    cur.close(); db.close()
    return jsonify({'success': True})

@app.route('/api/medicines/today')
@login_required
def api_medicines_today():
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT id, name, med_time FROM medicines WHERE user_id = %s AND taken = FALSE', (session['user_id'],))
    meds = cur.fetchall()
    cur.close(); db.close()
    return jsonify(meds)

# ─── Friends System ───

@app.route('/friend/request/<int:user_id>', methods=['POST'])
@login_required
def friend_request(user_id):
    if user_id == session['user_id']:
        return jsonify({'error': 'Cannot friend yourself'}), 400
    uid1, uid2 = sorted([session['user_id'], user_id])
    db = get_db()
    cur = db.cursor()
    cur.execute('SELECT * FROM friendships WHERE user_id1 = %s AND user_id2 = %s', (uid1, uid2))
    if cur.fetchone():
        cur.close(); db.close()
        return jsonify({'error': 'Already sent or friends'}), 400
    cur.execute('INSERT INTO friendships (user_id1, user_id2, requester_id, status) VALUES (%s, %s, %s, %s)',
                (uid1, uid2, session['user_id'], 'pending'))
    db.commit()
    cur.close(); db.close()
    return jsonify({'success': True})

@app.route('/friend/accept/<int:user_id>', methods=['POST'])
@login_required
def friend_accept(user_id):
    uid1, uid2 = sorted([session['user_id'], user_id])
    db = get_db()
    cur = db.cursor()
    cur.execute('UPDATE friendships SET status = %s WHERE user_id1 = %s AND user_id2 = %s AND requester_id = %s',
                ('accepted', uid1, uid2, user_id))
    db.commit()
    cur.close(); db.close()
    return jsonify({'success': True})

@app.route('/friend/reject/<int:user_id>', methods=['POST'])
@login_required
def friend_reject(user_id):
    uid1, uid2 = sorted([session['user_id'], user_id])
    db = get_db()
    cur = db.cursor()
    cur.execute('DELETE FROM friendships WHERE user_id1 = %s AND user_id2 = %s AND requester_id = %s',
                (uid1, uid2, user_id))
    db.commit()
    cur.close(); db.close()
    return jsonify({'success': True})

if __name__ == '__main__':
    app.run(debug=True, port=5000)
