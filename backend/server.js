require('dotenv').config();
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000; // Better practice for CDAC projects
const cors = require("cors");
const path = require('path');

// 1. GLOBAL MIDDLEWARE
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 2. STATIC FILES
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// 3. FRONTEND ROUTES (Reset Password)
app.get('/user/reset-password/:token', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'user-reset.html'));
});

app.get('/admin/reset-password/:token', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin-reset.html'));
});

// 4. API ROUTES
app.use('/complaints', require('./routes/complaint').ComplaintRouter);
app.use('/notifications', require('./routes/notification').NotificationRouter);

// User Routes
app.use('/user/auth', require('./routes/user/auth/auth.router'));
app.use('/user/profile', require('./routes/user/profile/profile.router'));
app.use('/user/password', require('./routes/user/password/password.router'));
app.use('/user/verify', require('./routes/user/verification/verification.router'));

// Admin Routes
app.use('/admin/auth', require('./routes/admin/auth/auth.router'));
app.use('/admin/profile', require('./routes/admin/profile/profile.router'));
app.use('/admin/password', require('./routes/admin/password/password.router'));

// 5. ERROR HANDLING MIDDLEWARE (Must be after routes)
app.use((err, req, res, next) => {
    console.error("SERVER ERROR:", err.stack);
    res.status(err.status || 500).json({
      success: false,
      message: err.message || 'Something went wrong!'
    });
});

app.listen(PORT, () => {
    console.log(`Jan Suvidha Server is live at ${PORT}`);
});