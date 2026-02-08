---
name: zepto
description: Complete Zepto automation - authentication, address setup, shopping, personalized recommendations based on order history, and payment link generation. Triggers on zepto, grocery, quick commerce, add to cart, milk, bread, butter, vegetables.
metadata: {"openclaw":{"emoji":"🛒","requires":{"config":["browser.enabled"]}}}
---

# Zepto India Grocery Skill

Complete end-to-end Zepto automation: authenticate user, confirm delivery address, shop for groceries with personalized recommendations, and generate Juspay payment links.

## Complete Flow
1. **Authentication** - Phone + OTP verification
2. **Address Confirmation** - Verify delivery location
3. **Shopping** - Search & add items (with YOUR usuals prioritized!)
4. **Payment Link** - Generate & send Juspay link via WhatsApp

---

## Step 0: Order History & Usuals

**Your order history is tracked in:** `{SKILL_DIR}/order-history.json`

(Where `{SKILL_DIR}` is your skill directory, typically `~/.openclaw/skills/zepto/`)

**Smart Selection Logic:**
1. When user requests an item (e.g., "add milk")
2. Check `order-history.json` for that category
3. **If ordered 2+ times** → Auto-add your most-ordered variant
4. **If ordered 0-1 times** → Show options and ask for selection

### Automated Order History Scraper

**When to run:** User says "update my zepto history" or "refresh order history"

**Process:**
1. Navigate to account page
2. Get all delivered order URLs
3. Visit each order sequentially
4. Extract items using DOM scraping
5. Build frequency map
6. Save to `order-history.json`

**Implementation:**
```bash
# Step 1: Navigate to account page
browser navigate url=https://www.zepto.com/account profile=openclaw

# Step 2: Extract order URLs
browser act profile=openclaw request='{"fn":"() => { const orders = []; document.querySelectorAll(\"a[href*=\\\"/order/\\\"]\").forEach(link => { if (link.href.includes(\"isArchived=false\") && link.textContent.includes(\"delivered\")) { orders.push(link.href); } }); return [...new Set(orders)]; }", "kind":"evaluate"}'
# Returns array of order URLs

# Step 3: For each order URL:
browser navigate url={order_url} profile=openclaw

# Step 4: Extract items from order page
browser act profile=openclaw request='{"fn":"() => { const items = []; document.querySelectorAll(\"*\").forEach(el => { const text = el.textContent; if (text.match(/\\d+\\s*unit/i)) { const parent = el.closest(\"div\"); if (parent) { const lines = parent.textContent.split(\"\\n\").map(l => l.trim()).filter(l => l && l.length > 5 && l.length < 100); if (lines[0]) { const qtyMatch = text.match(/(\\d+)\\s*unit/i); items.push({ name: lines[0], quantity: qtyMatch ? parseInt(qtyMatch[1]) : 1 }); } } } }); const uniqueItems = {}; items.forEach(item => { if (!uniqueItems[item.name]) uniqueItems[item.name] = item; }); return Object.values(uniqueItems); }", "kind":"evaluate"}'
# Returns array of {name, quantity}

# Step 5: Aggregate all items into frequency map
# Build JSON structure with counts

# Step 6: Write to file
write path={SKILL_DIR}/order-history.json content={json_data}
```

**Automated scraper advantages:**
- ✅ No manual screenshot review
- ✅ Faster (visits all orders programmatically)
- ✅ Always up-to-date
- ✅ Can re-run anytime

**Example:**
```
User: "Update my Zepto order history"

Response:
"🔍 Scanning your Zepto orders...
📦 Found 6 delivered orders
🔄 Extracting items...
✅ Updated! Found:
   - Coriander: 4 orders
   - Milk: 3 orders
   - Bread: 2 orders
   - Potato: 2 orders
   + 15 other items

Your usuals are ready!"
```

---

**Smart Selection Logic (Using History):**

**Example:**
```
User: "Add milk"

[Check order-history.json]
→ "Amul Taaza Toned Fresh Milk | Pouch (500ml)" ordered 3x

Response:
"🥛 Adding your usual milk!
Amul Taaza Toned Fresh Milk (500ml) - ₹29
📊 You've ordered this 3 times
✅ Added to cart"
```

**If only ordered once or never:**
```
User: "Add milk"

[Check order-history.json]
→ "Amul Taaza" ordered 1x only

Response:
"🥛 Found some milk options:
1. Amul Taaza Toned (500ml) - ₹29 ⭐ 4.8 (100k) - You've ordered this once
2. Amul Gold (1L) - ₹68 ⭐ 4.9 (80k) - Most popular
3. Mother Dairy (500ml) - ₹30 ⭐ 4.7 (60k)

Which one? (or tell me a number)"
```

**Update order history:** After each successful order, update the JSON file with new items.

---

## Step 1: Authentication (First Time Only)

**Check if already logged in:**
```bash
browser open url=https://www.zepto.com profile=openclaw
browser snapshot --interactive profile=openclaw
# Look for "login" button vs "profile" link
```

**If NOT logged in, start auth flow:**

### 1.1: Get Phone Number
Ask user: "What's your phone number for Zepto? (10 digits)"

### 1.2: Enter Phone & Request OTP
```bash
# Click login button
browser act profile=openclaw request='{"kind":"click","ref":"{login_button_ref}"}'

# Type phone number
browser act profile=openclaw request='{"kind":"type","ref":"{phone_input_ref}","text":"{phone}"}'

# Click Continue
browser act profile=openclaw request='{"kind":"click","ref":"{continue_button_ref}"}'
```

### 1.3: Get OTP from User
Ask user: "I've sent the OTP to {phone}. What's the OTP you received?"

### 1.4: Enter OTP
```bash
browser snapshot --interactive profile=openclaw  # Get OTP input refs
browser act profile=openclaw request='{"kind":"type","ref":"{otp_input_ref}","text":"{otp}"}'
# OTP auto-submits after 6 digits
```

**Result:** User is now logged in! Session persists across browser restarts.

---

## Step 2: Address Confirmation

**Open location selector:**
```bash
# Click "Select Location" button
browser act profile=openclaw request='{"kind":"click","ref":"{select_location_button_ref}"}'
browser screenshot profile=openclaw  # Show user their saved addresses
```

**Ask user to confirm:**
```
Your saved addresses:
1. Home - 123 Main Street, Mumbai
2. Office - 456 Park Avenue, Delhi

Which address for delivery? (Reply with number or name)
```

**Select address (CRITICAL TECHNIQUE):**
The address name itself is clickable in the modal! Use JavaScript to find and click it:
```bash
# Replace {USER_ADDRESS_NAME} with the actual address name user selected
browser act profile=openclaw request='{"fn":"() => { const headings = document.querySelectorAll(\"h1, h2, h3, h4, h5, h6, p, span, div\"); for (let h of headings) { if (h.textContent.trim() === \"{USER_ADDRESS_NAME}\" && h.offsetParent !== null) { h.click(); return \"clicked: \" + h.tagName; } } return \"not found\"; }","kind":"evaluate"}'
```

**KEY INSIGHT:** The address name (e.g., "Home", "Office") shows a hand cursor on hover and is directly clickable. Don't try to click containers or buttons around it - click the text element itself.

**Confirm serviceability:**
```bash
browser navigate url=https://www.zepto.com profile=openclaw
# Check for "Store closed" or "Not serviceable" warnings
```

**Report to user:**
```
✅ Delivery address: {address_name}
📍 {full_address}
⏱️ ETA: {eta} mins
🏪 Store: {store_name}

Ready to shop! What would you like to add to cart?
```

---

## Step 3: Shopping

### 3A: Discovery Mode (Browse & Explore)

When user asks to "explore", "show me", "what's good", "find something", or "discover":

**Common Discovery Patterns:**
- "Show me healthy snacks under ₹50"
- "What's good in dairy products?"
- "Find me something for breakfast"
- "Any deals on fruits?"
- "Discover protein bars"

**Browse Categories:**
```bash
# Navigate to category pages
browser navigate url=https://www.zepto.com profile=openclaw
browser snapshot --interactive profile=openclaw

# Categories available on homepage:
# - Fruits & Vegetables
# - Dairy, Bread & Eggs
# - Munchies (snacks)
# - Cold Drinks & Juices
# - Breakfast & Sauces
# - Atta, Rice, Oil & Dals
# - Cleaning Essentials
# - Bath & Body
# - Makeup & Beauty
```

**Filter & Sort:**
```bash
# Example: Browse "Munchies" category
browser navigate url=https://www.zepto.com/pn/munchies profile=openclaw
browser snapshot --interactive profile=openclaw

# Take screenshot to show user the options
browser screenshot profile=openclaw
```

**Discovery Response Format:**
```
🔍 Found some great options in {category}:

1. **{Product Name}** - ₹{price} ({discount}% OFF)
   ⭐ {rating} ({review_count} reviews)
   📦 {size/quantity}
   
2. **{Product Name}** - ₹{price}
   ⭐ {rating} ({review_count} reviews)
   
3. **{Product Name}** - ₹{price} ({discount}% OFF)
   ⭐ {rating} ({review_count} reviews)

Want me to add any of these? Just tell me the number(s)!
```

**Smart Filtering Tips:**
- Price range: Extract from query ("under ₹50", "below 100")
- Discount focus: Look for items with ₹X OFF tags
- High ratings: Prioritize 4.5+ star products
- Popular items: Sort by review count (k = thousands)
- Health focus: Keywords like "protein", "sugar-free", "organic", "millet"

**Interactive Discovery:**
After showing options, user can:
- Add by number: "Add 1 and 3"
- Ask for more: "Show me more"
- Refine: "Show cheaper options" or "What about chocolate flavors?"
- Browse different category: "Now show me dairy products"

### 3B: Direct Search (Specific Items)

When user names a specific item:

```bash
browser navigate url=https://www.zepto.com/search?query={item} profile=openclaw
browser snapshot --interactive profile=openclaw
```

### Select Best Product
**Rule:** Pick product with highest review count.

Format: `{rating} ({count})` where k=thousand, M=million.

Example: "4.8 (694.4k)" = 694,400 reviews = most popular.

### Add to Cart
```bash
browser act profile=openclaw request='{"kind":"click","ref":"{ADD_button_ref}"}'
```

### Multi-Item Flow
For "add milk, butter, bread":
1. Search milk → pick best → ADD
2. Search butter → pick best → ADD
3. Search bread → pick best → ADD
4. View cart summary

**CRITICAL - Quantity Mapping:**
When user provides a shopping list with quantities (e.g., "3x jeera, 2x saffola oats"):
1. **ALWAYS create a mapping file FIRST** before any cart operations
2. Map each item name to its requested quantity
3. Before removing/modifying items, **verify against this mapping**
4. Never assume which item has which quantity - CHECK THE MAPPING

Example mapping:
```json
{
  "jeera": 3,
  "saffola_oats": 2,
  "milk": 1
}
```

**Before removing duplicates or adjusting quantities:**
- Take a cart snapshot
- Match cart items to your mapping by name similarity
- Verify quantities match the original request
- If unsure, ASK the user before making changes

### View Cart
```bash
browser navigate url=https://www.zepto.com/?cart=open profile=openclaw
browser snapshot profile=openclaw  # Get cart summary
```

---

## Step 4: Generate Payment Link

After all items added to cart:

### 4.1: Proceed to Payment
```bash
browser act profile=openclaw request='{"kind":"click","ref":"{proceed_to_payment_button_ref}"}'
# Wait for redirect to Juspay
```

### 4.2: Extract Juspay Link
**URL Format:**
```
https://payments.juspay.in/payment-page/signature/zeptomarketplace-{order_id}
```

Example:
```
https://payments.juspay.in/payment-page/signature/zeptomarketplace-019c2a455a630000000000009e6f261c
```

### 4.3: Send Link via WhatsApp
```bash
message action=send channel=whatsapp target={user_phone} message="🛒 Your Zepto order is ready!

{cart_summary}

💰 Total: ₹{total}

🔗 Click here to pay:
{juspay_payment_link}

After payment, your order will be confirmed automatically! 🚀"
```

**Payment Link Features:**
- ✅ Shareable across devices
- ✅ Works on mobile browser
- ✅ Redirects to Zepto after payment
- ✅ Order confirmed automatically
- ✅ Secure (Juspay gateway)

---

## Response Format

**After successful cart + payment link generation:**
```
🛒 Added to Zepto cart:
- Amul Gold Milk (1L) - ₹68 (4.8★, 100k reviews)
- Amul Butter (100g) - ₹58 (4.9★, 50k reviews)
- Britannia Bread (400g) - ₹42 (4.7★, 80k reviews)

💰 Total: ₹168

🔗 Payment link sent to your WhatsApp!
Click the link to pay and confirm your order. Delivery in ~15 mins! 🚀
```

---

## Safety & Best Practices

✅ **DO:**
- Check auth status before every order
- Confirm address with user
- Extract payment link accurately
- Send link via WhatsApp
- Let user complete payment

❌ **DON'T:**
- Never click "Pay" button
- Never store OTP
- Never auto-submit payment
- Never change address without user confirmation

---

## Error Handling

**Phone number invalid:**
```
"Phone number should be 10 digits. Please try again."
```

**OTP verification failed:**
```
"OTP verification failed. Let me resend the OTP.
Check your phone for the new code."
```

**Location not serviceable:**
```
"⚠️ Your location is currently not serviceable by Zepto.
Store might be temporarily closed or location outside delivery zone.
Want to try a different address?"
```

**Item not found:**
```
"Couldn't find {item} on Zepto. Try a different search term?"
```

---

## Session Persistence

**After successful authentication:**
- Browser cookies persist login
- No need to re-authenticate for future orders
- Address selection persists
- Can directly proceed to shopping

**To check if authenticated:**
```bash
browser navigate url=https://www.zepto.com profile=openclaw
browser snapshot --interactive profile=openclaw
# If "profile" link exists → logged in
# If "login" button exists → need to auth
```
