# Conversation Triage Guide

Rules for automatically assigning incoming support conversations to the correct team. Conversations arrive via the FeatureBase chat widget — users pick a category from a bot flow, then describe their issue.

## Key Principle

**Context matters more than the bot category label.** Users often pick the wrong bot flow (e.g., selecting "Technical issue ⚙️" when they actually have a verification problem). Always read the actual message content before assigning.

## Team Assignment Rules

### Re-Verification / KYC Team
Identity verification, KYB/KYC, and onboarding document issues.

**Match criteria:**
- Bot-triaged title: "Onboarding / Verification 🔄"
- Keywords: verification, KYB, KYC, re-verification, identity, onboarding, ID card, document, passport
- Chinese keywords: 验证, 身份证, 审核
- ContactForm "Issue Report" mentioning verification/identity topics (even if submitted under "Technical issue")
- Users unable to pass identity verification (regardless of which bot flow they selected)

**Examples from real tickets:**
- "Chinese ID card cannot pass identity verification" → Re-Verification (even though submitted as "Technical issue")
- "I have updated my website to comply with the AI Wrapper policy" → Re-Verification
- User sends KYC URL (`/dashboard/kyc/...`) → Re-Verification

### Technical Issue Team
Subscription billing, webhook events, payment flow bugs, and integration/API issues.

**Match criteria:**
- Bot-triaged title: "Technical issue ⚙️" (when content is actually technical)
- Subscription billing: failed charges, pending transactions, proration problems, upgrade not charging
- Webhook events: missing events, wrong event types (e.g., `subscription.canceled` vs `subscription.scheduled_cancel`)
- Payment flow: checkout redirects to wrong URL, card blocked in test mode, passback URL issues
- Integration/API: trial-to-paid conversion bugs, subscription upgrades not working as expected
- Renewal failures: subscription renewal charge failures, stuck in pending status
- ContactForm "Issue Report" with payment/billing/webhook/integration topics

**Examples from real tickets:**
- "Plan upgrade is not getting charged when it should in Test Mode" → Technical Issue
- "subscription.canceled vs subscription.scheduled_cancel webhook confusion" → Technical Issue
- "Passback URL sent me to a random website" → Technical Issue
- "My subscription renewal failed, transaction status is Pending" → Technical Issue
- "Several subscription users' renewals all failed" → Technical Issue

### Customer Requests Team
Refund requests and account-level customer service.

**Match criteria:**
- ContactForm: "Refund Request"
- Order cancellation requests

### Sales Team
Pre-sales inquiries, demos, and volume pricing.

**Match criteria:**
- ContactForm: "Sales Inquiry"
- Demo requests
- Volume/pricing questions from prospects

### Payouts Team
Payout processing, withdrawal issues, rejected payouts.

**Match criteria:**
- Payout-related issues (rejected, delayed, failed)
- Withdrawal questions

### Product Question Team
General product usage questions that don't fit other categories.

### Other Team
Catch-all for anything that doesn't clearly fit above.

## Automation Tips

- During off-hours (e.g., 21:00–09:00), auto-triage unassigned conversations using these rules
- Track assigned conversation IDs in a state file to avoid duplicate notifications
- When auto-assigning, notify the team lead on the messaging platform
- Some conversations need human judgment — when unsure, leave unassigned for the support team
