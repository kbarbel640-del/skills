# Zepto India Grocery Automation Skill 🛒

Complete end-to-end Zepto grocery automation for OpenClaw - from authentication to checkout with personalized recommendations based on YOUR order history.

## Features

### 🔐 Authentication
- Phone + OTP verification
- Automatic login state detection

### 📍 Smart Address Selection
- Shows your saved addresses
- Click address name to select (breakthrough technique!)
- Confirms serviceability before shopping

### 🛍️ Personalized Shopping
- **Learn your usuals** - Auto-adds items you've ordered 2+ times
- **Discovery mode** - Browse categories, filter by price/ratings
- Search & add items to cart
- Replace out-of-stock items intelligently

### 💳 Payment Link Generation
- Generates Juspay payment link
- Sends via WhatsApp automatically
- Shows order breakdown

### 📊 Order History Tracking
- **Automated scraper** - Extracts all past orders via DOM parsing
- Builds item frequency database
- No screenshots needed - pure JavaScript evaluation
- Updates after each order

## Installation

```bash
# Clone/download this skill to your OpenClaw skills directory
mkdir -p ~/.openclaw/skills/zepto
# Copy SKILL.md and order-history-template.json to that directory

# Rename template to start fresh
cp order-history-template.json order-history.json
```

## Requirements

- OpenClaw with browser capabilities enabled
- WhatsApp channel configured (for payment links)
- Zepto account with Indian phone number

## Usage Examples

### First Time Setup
```
You: "Order groceries from Zepto"
AI: "What's your phone number?" → Enter OTP → Select address
```

### Smart Shopping (Usuals)
```
You: "Add milk"
AI: "🥛 Adding your usual! Amul Taaza (500ml) - ordered 3x ✅"
```

### Discovery Mode
```
You: "Show me healthy snacks under ₹50"
AI: [Shows top 3-5 options with ratings, prices, deals]
```

### Order History Update
```
You: "Update my Zepto order history"
AI: "🔍 Scanning... Found 6 orders... ✅ Updated!"
```

## How It Works

### Authentication Flow
1. Check if logged in
2. Enter phone number → request OTP
3. User provides OTP → verify
4. Session maintained in browser

### Address Selection Breakthrough
**Discovery:** Address names themselves are clickable elements!
```javascript
// Find and click address by name
document.querySelectorAll('h1, h2, h3, h4, h5, h6, p, span, div')
  .find(el => el.textContent.trim() === 'Home' && el.offsetParent !== null)
  .click();
```

### Shopping Logic
1. **Check order history** for item category
2. **If 2+ orders:** Auto-add most-ordered variant
3. **If 0-1 orders:** Show options, ask user
4. Search Zepto, parse results, add to cart

### Payment Link Generation
1. Navigate to cart → checkout
2. Extract Juspay redirect URL
3. Send via WhatsApp with order breakdown

### Order History Scraper
```javascript
// 1. Get all delivered order URLs
const orders = Array.from(document.querySelectorAll('a[href*="/order/"]'))
  .filter(link => link.href.includes('delivered'));

// 2. Visit each order, extract items via DOM
// 3. Build frequency map: { "milk": { "Amul Taaza": 3, ... } }
// 4. Save to order-history.json
```

## File Structure

```
zepto/
├── SKILL.md                      # Main skill instructions
├── README.md                     # This file
├── order-history.json            # Your personalized order data
└── order-history-template.json   # Empty template
```

## Privacy Note

- **order-history.json** contains YOUR personal order data
- When sharing this skill, use the template version (empty)
- Each user builds their own history after installation

## Advanced Features

### Discovery Mode
Browse by category, price, ratings without screenshots:
- "Show healthy snacks under ₹100"
- "Find high-protein breakfast options"
- "What's on sale in dairy?"

### Smart Replacements
When items are out of stock:
- Suggests similar alternatives
- Considers your past orders
- Explains price differences

### Multi-Address Support
- Saves multiple delivery locations
- Asks which address each order
- Remembers last used address

## Troubleshooting

**"Can't find address"**
→ Make sure you have saved addresses in your Zepto account first

**"Order history empty"**
→ Run "Update my Zepto order history" to scrape your past orders

**"Payment link not generated"**
→ Check WhatsApp channel is configured in OpenClaw

## Contributing

Found improvements? Submit to [ClawHub](https://clawhub.com)!

## Credits

Built with ❤️ for the OpenClaw community
Zepto automation skill - Jan-Feb 2026

## License

MIT - Free to use, modify, and share
