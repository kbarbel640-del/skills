# Implementation Guide for SEO Content Engine

This guide explains how the SEO Content Engine skill works internally.

## Core Workflow

### Step 1: Input Processing

```javascript
// Parse user request
const input = {
  keyword: extractKeyword(userMessage),
  tone: extractTone(userMessage) || 'professional',
  length: extractLength(userMessage) || 'medium', // short/medium/long
  audience: extractAudience(userMessage) || 'general',
  includeSections: extractSections(userMessage) || []
};
```

### Step 2: Keyword Research

Use web_search to gather data:

```
web_search({
  query: input.keyword + " search volume competition",
  count: 5
})
```

Also search for related keywords:
```
web_search({
  query: "best " + input.keyword + " related keywords long-tail",
  count: 5
})
```

### Step 3: Competitor Discovery

```
web_search({
  query: input.keyword,
  count: 10
})
```

Extract top 5 non-sponsored, non-video results.

### Step 4: Competitor Analysis

For each competitor URL:
```
web_fetch({
  url: competitorUrl,
  maxChars: 5000
})
```

Analyze:
- Word count
- Heading structure (H1, H2, H3)
- Content format (listicle, guide, review)
- Unique angles or topics covered
- Missing information (gaps)

### Step 5: Content Generation

Based on analysis, create:

1. **Title** — Include keyword, add power words, keep under 60 chars
2. **Meta Description** — 150-160 chars, include keyword + call to action
3. **Outline** — Use competitor structure as base, add unique sections
4. **Content** — Write sections following SEO best practices:
   - Keyword in first 100 words
   - Keyword in at least one H2
   - Related keywords throughout
   - Short paragraphs (2-3 sentences)
   - Bullet points for readability
   - Internal linking placeholders

### Step 6: SEO Optimization Check

Verify:
- [ ] Title length: 50-60 characters
- [ ] Meta description: 150-160 characters
- [ ] Keyword in URL (suggested slug)
- [ ] Keyword in first paragraph
- [ ] Keyword in at least one H2 heading
- [ ] Keyword density: 1-2%
- [ ] At least 3 internal link suggestions
- [ ] Image alt text suggestions with keyword
- [ ] Schema.org type identified (Article, HowTo, FAQ)

## Implementation Example

Here's a minimal working implementation:

```
User: "Generate SEO content about best hiking boots for beginners"

1. Search: "best hiking boots for beginners search volume"
2. Search: "best hiking boots for beginners" → Get top 5 URLs
3. Fetch each URL → Analyze content
4. Generate:
   - Title: "10 Best Hiking Boots for Beginners (2026 Buying Guide)"
   - Meta: "Find the perfect hiking boots for beginners. Our 2026 guide covers top-rated options, expert tips, and what to look for in your first pair."
   - Structure: Introduction → Why proper boots matter → Top 10 list → Buying guide → Care tips → FAQ
5. Write full content with proper formatting
6. Generate SEO report with scores
```

## Free Tier Limitations

To enforce free tier (3 articles/month):

1. Track usage in workspace file:
```json
{
  "seoContentEngine": {
    "freeUsesThisMonth": 2,
    "lastResetDate": "2026-02-01",
    "totalGenerated": 5
  }
}
```

2. Check before generating:
```javascript
if (usage.freeUsesThisMonth >= 3 && !hasPremiumKey()) {
  return "Free tier limit reached (3/month). Upgrade to Premium for unlimited access.";
}
```

## Premium Tier Features

For API key validation:

```javascript
async function validatePremiumKey(key) {
  // Call your validation endpoint
  const response = await fetch('https://your-api.com/validate', {
    method: 'POST',
    headers: { 'Authorization': 'Bearer ' + key }
  });
  return response.ok;
}
```

## Output Templates

### Article Template

```markdown
# {{title}}

{{introduction}}

## Table of Contents
{{toc}}

{{sections}}

## Conclusion
{{conclusion}}

---

**Related Articles:**
- [Internal Link 1]
- [Internal Link 2]
- [Internal Link 3]
```

### SEO Report Template

```markdown
## SEO Checklist for "{{keyword}}"

| Element | Status | Value |
|---------|--------|-------|
| Title Length | ✅ | {{titleLength}}/60 chars |
| Meta Description | ✅ | {{metaLength}}/160 chars |
| Keyword in Title | ✅ | Yes |
| Keyword in First 100 Words | ✅ | Yes |
| Keyword in H2 | ✅ | {{h2Count}} times |
| Keyword Density | ✅ | {{density}}% |
| Word Count | ✅ | {{wordCount}} words |
| Readability Score | ✅ | Grade {{grade}} |
| Internal Links | ✅ | {{linkCount}} suggestions |
| Schema Markup | ✅ | {{schemaType}} |

**Overall SEO Score: {{score}}/100**
```

## Testing Checklist

Before publishing the skill:

- [ ] Test with 5 different keywords
- [ ] Verify word count meets requirements
- [ ] Check keyword placement in output
- [ ] Validate competitor analysis accuracy
- [ ] Test free tier limit enforcement
- [ ] Verify premium key validation (if applicable)
- [ ] Check formatting and readability
- [ ] Test edge cases (very short/long keywords, special characters)

## Monetization Strategy

### Phase 1: Launch (Free Only)
- Build user base
- Collect feedback
- Refine algorithm
- Establish reputation

### Phase 2: Freemium
- Launch premium tier with API keys
- Keep free tier as lead generation
- Upsell through skill output ("Upgrade for unlimited...")

### Phase 3: Services
- Offer done-for-you content services
- Use skill as proof of capability
- Higher margins than API subscriptions

### Revenue Projections

**Month 1-2:**
- Free users: 50-100
- Premium users: 0-5
- Service clients: 0-2
- Revenue: $0-300

**Month 3-6:**
- Free users: 300-500
- Premium users: 10-20
- Service clients: 2-5
- Revenue: $500-2,000/mo

**Month 6-12:**
- Free users: 1000+
- Premium users: 30-50
- Service clients: 5-10
- Revenue: $2,000-5,000/mo

---

**Next Steps:**
1. Implement basic workflow
2. Test with real keywords
3. Publish to ClawHub
4. Promote on Moltbook/Twitter
5. Gather feedback and iterate
