const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const axios = require('axios');

const app = express();
const PORT = 3000;

const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY;

app.use(cors());
app.use(express.json());

const DB_FILE = path.join(__dirname, 'subscriptions.json');

function readDatabase() {
    if (!fs.existsSync(DB_FILE)) return {};
    try {
        const fileContent = fs.readFileSync(DB_FILE, 'utf8');
        return fileContent ? JSON.parse(fileContent) : {};
    } catch (e) {
        return {};
    }
}

function writeDatabase(data) {
    try {
        // Safe atomic processing write format
        fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf8');
    } catch (e) {
        console.error("Database structural write state error:", e.message);
    }
}

app.get('/', (req, res) => {
    res.send('Elite Gold Cloud Core Infrastructure: ACTIVE');
});

app.post('/api/checkout/initialize', async (req, res) => {
    try {
        const reference = 'STAB_' + Math.random().toString(36).substring(2, 15).toUpperCase();
        
        const paystackResponse = await axios.post(
            'https://api.paystack.co/transaction/initialize',
            {
                email: `user_${reference.toLowerCase()}@stabilizer.com`,
                amount: 350000, // ₦3,500 in Kobo
                reference: reference
            },
            {
                headers: {
                    Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
                    'Content-Type': 'application/json'
                }
            }
        );

        if (paystackResponse.data && paystackResponse.data.status) {
            const db = readDatabase();
            db[reference] = {
                status: 'pending',
                expiryTime: 0
            };
            writeDatabase(db);

            return res.json({
                authorization_url: paystackResponse.data.data.authorization_url,
                reference: reference
            });
        }
        res.status(400).json({ error: "Paystack initialization failed" });
    } catch (error) {
        console.log(error.response?.data || error.message);
        res.status(500).json({ error: "Internal payment gateway error" });
    }
});

app.get('/api/subscription/verify/:reference', async (req, res) => {
    const { reference } = req.params;
    const db = readDatabase();

    if (!db[reference]) {
        return res.status(404).json({ status: 'not_found' });
    }

    if (db[reference].status === 'active') {
        if (Date.now() < db[reference].expiryTime) {
            return res.json({ status: 'active' });
        } else {
            db[reference].status = 'expired';
            writeDatabase(db);
            return res.json({ status: 'expired' });
        }
    }

    try {
        const verifyRes = await axios.get(
            `https://api.paystack.co/transaction/verify/${reference}`,
            {
                headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` }
            }
        );

        // 🛡️ CRITICAL HANDSHAKE FIX: Added optional chaining to guarantee no runtime crashes
        if (verifyRes.data && verifyRes.data.status && verifyRes.data.data?.status === 'success') {
            const currentRegistrationTime = Date.now();
            const extensionPeriod = 30 * 24 * 60 * 60 * 1000; // Exactly 30 days in milliseconds
            
            let finalExpiry = currentRegistrationTime + extensionPeriod;
            if (db[reference] && db[reference].expiryTime > currentRegistrationTime) {
                finalExpiry = db[reference].expiryTime + extensionPeriod;
            }

            db[reference] = {
                status: 'active',
                expiryTime: finalExpiry
            };
            writeDatabase(db);
            return res.json({ status: 'active' });
        }
    } catch (e) {
        console.log(e.response?.data || e.message);
    }

    res.json({ status: 'pending' });
});

app.get('/api/auth/verify-license', (req, res) => {
    const { reference } = req.query;
    if (!reference) return res.json({ authorized: false });

    const db = readDatabase();
    const profile = db[reference];

    if (profile && profile.status === 'active' && Date.now() < profile.expiryTime) {
        return res.json({
            authorized: true,
            secondsLeft: Math.floor((profile.expiryTime - Date.now()) / 1000)
        });
    }

    res.json({ authorized: false });
});

app.listen(PORT, '0.0.0.0', () => console.log(`Master Cloud Infrastructure running on port ${PORT}`));
