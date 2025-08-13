const express = require('express');
const bcrypt = require('bcryptjs');
const router = express.Router();

router.get('/', async (req, res) => {
  const users = await User.find({}, 'name email');
  res.json(users);
});

router.post('/change-password', async (req, res) => {
  const { email, newPassword } = req.body;
  const hashed = await bcrypt.hash(newPassword, 10);
  await User.findOneAndUpdate({ email }, { password: hashed });
  res.json({ message: 'Password updated successfully' });
});

module.exports = router;
