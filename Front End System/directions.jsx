/* Visual Directions — StudyApp */

// ─── Direction 1: Ink & Paper ───────────────────────────────────────
const InkPalette = () => {
  const colors = [
    { name: 'Parchment', hex: '#F5F0E8', dark: false },
    { name: 'Warm Gray', hex: '#E0DAD0', dark: false },
    { name: 'Stone', hex: '#8C8577', dark: false },
    { name: 'Ink', hex: '#1A1816', dark: true },
    { name: 'Terracotta', hex: '#C4654A', dark: true },
    { name: 'Sage', hex: '#7A9178', dark: true },
  ];
  const darkColors = [
    { name: 'Deep Ink', hex: '#141210', dark: true },
    { name: 'Charcoal', hex: '#1E1C19', dark: true },
    { name: 'Warm Dark', hex: '#2A2722', dark: true },
    { name: 'Cream Text', hex: '#E8E2D8', dark: false },
    { name: 'Terracotta', hex: '#D4755A', dark: true },
    { name: 'Sage', hex: '#8AA188', dark: false },
  ];
  return (
    <div style={{ fontFamily: "'DM Sans', sans-serif", padding: 40, background: '#F5F0E8', width: '100%', height: '100%' }}>
      <h2 style={{ fontFamily: "'Instrument Serif', serif", fontSize: 42, color: '#1A1816', marginBottom: 6 }}>
        Ink &amp; Paper
      </h2>
      <p style={{ fontSize: 15, color: '#8C8577', marginBottom: 28, maxWidth: 460, lineHeight: 1.5 }}>
        Warm, editorial. Feels like a well-loved notebook. Serif display type adds gravitas without stuffiness. Terracotta accent is energizing but calm.
      </p>

      <div style={{ display: 'flex', gap: 24, marginBottom: 32, flexWrap: 'wrap' }}>
        <PaletteBlock title="Light Mode" colors={colors} />
        <PaletteBlock title="Dark Mode" colors={darkColors} />
      </div>

      <Section title="Type System">
        <TypeRow label="Display" family="'Instrument Serif', serif" size={36} weight={400} sample="Organic Chemistry" color="#1A1816" />
        <TypeRow label="Heading" family="'DM Sans', sans-serif" size={20} weight={600} sample="Today's Review" color="#1A1816" />
        <TypeRow label="Body" family="'DM Sans', sans-serif" size={15} weight={400} sample="You have 14 cards due across 3 decks. Your streak is 7 days." color="#4A4640" />
        <TypeRow label="Caption" family="'DM Sans', sans-serif" size={12} weight={500} sample="LAST REVIEWED 2H AGO" color="#8C8577" />
      </Section>

      <Section title="Icon Style">
        <p style={{ fontSize: 14, color: '#8C8577', marginBottom: 8 }}>Linear, 1.5px stroke, rounded caps. Warm and hand-drawn feeling.</p>
      </Section>

      <Section title="Signature Element">
        <p style={{ fontSize: 14, color: '#1A1816', lineHeight: 1.6 }}>
          Knowledge heatmap rendered as <strong>watercolor-style swatches</strong> — soft, organic blobs with varying terracotta/sage saturation representing mastery. Progress feels alive, not clinical.
        </p>
        <div style={{ display: 'flex', gap: 6, marginTop: 12, flexWrap: 'wrap' }}>
          {[0.15, 0.3, 0.5, 0.7, 0.9, 1].map((o, i) => (
            <div key={i} style={{
              width: 44, height: 44, borderRadius: '50% 40% 50% 45%',
              background: `oklch(${0.45 + o * 0.25} ${0.08 + o * 0.08} ${o > 0.5 ? 145 : 25})`,
              opacity: 0.5 + o * 0.5,
            }} />
          ))}
        </div>
      </Section>
    </div>
  );
};

const InkHomeScreen = () => (
  <IOSDevice screenTitle="" statusBarVariant="dark">
    <div style={{
      fontFamily: "'DM Sans', sans-serif",
      background: '#F5F0E8',
      minHeight: '100%',
      padding: '16px 20px',
      color: '#1A1816',
    }}>
      <p style={{ fontSize: 13, color: '#8C8577', marginBottom: 2, fontWeight: 500 }}>Wednesday, April 23</p>
      <h1 style={{ fontFamily: "'Instrument Serif', serif", fontSize: 30, fontWeight: 400, marginBottom: 20 }}>
        Good evening, Maya
      </h1>

      {/* Streak */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 20 }}>
        <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#C4654A' }} />
        <span style={{ fontSize: 13, color: '#8C8577' }}>7 day streak</span>
        <div style={{ flex: 1 }} />
        <span style={{ fontSize: 13, color: '#C4654A', fontWeight: 500 }}>14 cards due</span>
      </div>

      {/* Continue card */}
      <div style={{
        background: '#1A1816', borderRadius: 14, padding: '18px 20px', color: '#F5F0E8', marginBottom: 16,
      }}>
        <p style={{ fontSize: 11, fontWeight: 500, letterSpacing: 0.5, color: '#8C8577', marginBottom: 6 }}>CONTINUE</p>
        <p style={{ fontSize: 17, fontWeight: 500, marginBottom: 4 }}>Organic Chemistry — Ch. 5</p>
        <p style={{ fontSize: 13, color: '#A09A90' }}>8 cards remaining · 4 min</p>
      </div>

      {/* Section */}
      <p style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.8, color: '#8C8577', marginBottom: 10, marginTop: 8 }}>
        RECENT
      </p>
      {['Cell Biology Midterm', 'Linear Algebra — Ch. 3', 'Psych 101 Notes'].map((t, i) => (
        <div key={i} style={{
          background: '#EDE8DE', borderRadius: 10, padding: '14px 16px', marginBottom: 8,
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        }}>
          <div>
            <p style={{ fontSize: 15, fontWeight: 500 }}>{t}</p>
            <p style={{ fontSize: 12, color: '#8C8577' }}>{['12 cards', '8 cards', '20 cards'][i]} · {['Quiz ready', 'Podcast ready', 'Summary'][i]}</p>
          </div>
          <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M8 5l5 5-5 5" stroke="#8C8577" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </div>
      ))}

      {/* Mini heatmap */}
      <p style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.8, color: '#8C8577', marginBottom: 10, marginTop: 20 }}>
        THIS WEEK
      </p>
      <div style={{ display: 'flex', gap: 5, flexWrap: 'wrap' }}>
        {[0.9, 0.7, 0.4, 0.8, 0.6, 0.2, 0].map((o, i) => (
          <div key={i} style={{
            width: 38, height: 38, borderRadius: '50% 40% 50% 45%',
            background: o > 0 ? `oklch(${0.45 + o * 0.25} ${0.06 + o * 0.1} ${o > 0.5 ? 145 : 25})` : '#E0DAD0',
            opacity: o > 0 ? 0.5 + o * 0.5 : 0.4,
          }} />
        ))}
      </div>

      {/* Bottom nav placeholder */}
      <div style={{
        display: 'flex', justifyContent: 'space-around', marginTop: 28, paddingTop: 12,
        borderTop: '1px solid #E0DAD0', color: '#8C8577', fontSize: 10, fontWeight: 500,
      }}>
        {['Home', 'Library', 'Study', 'Progress', 'Profile'].map((t, i) => (
          <div key={i} style={{ textAlign: 'center', color: i === 0 ? '#C4654A' : '#8C8577' }}>
            <div style={{ width: 22, height: 22, borderRadius: 6, background: i === 0 ? '#C4654A' : '#D5D0C6', margin: '0 auto 4px', opacity: i === 0 ? 0.15 : 0.4 }} />
            {t}
          </div>
        ))}
      </div>
    </div>
  </IOSDevice>
);

// ─── Direction 2: Soft Focus ────────────────────────────────────────
const SoftPalette = () => {
  const colors = [
    { name: 'Snow', hex: '#F8F7FC', dark: false },
    { name: 'Mist', hex: '#EEEDF5', dark: false },
    { name: 'Lavender Gray', hex: '#9994B0', dark: false },
    { name: 'Charcoal', hex: '#2D2B3D', dark: true },
    { name: 'Indigo', hex: '#5B4FC4', dark: true },
    { name: 'Peach', hex: '#E8946A', dark: true },
  ];
  const darkColors = [
    { name: 'Deep Purple', hex: '#141320', dark: true },
    { name: 'Plum', hex: '#1C1B2E', dark: true },
    { name: 'Muted', hex: '#2A2940', dark: true },
    { name: 'Light', hex: '#E8E6F0', dark: false },
    { name: 'Bright Indigo', hex: '#7B6FE8', dark: true },
    { name: 'Peach', hex: '#EEA47A', dark: true },
  ];
  return (
    <div style={{ fontFamily: "'Outfit', sans-serif", padding: 40, background: '#F8F7FC', width: '100%', height: '100%' }}>
      <h2 style={{ fontSize: 40, fontWeight: 700, color: '#2D2B3D', marginBottom: 6, letterSpacing: -0.5 }}>
        Soft Focus
      </h2>
      <p style={{ fontSize: 15, color: '#9994B0', marginBottom: 28, maxWidth: 460, lineHeight: 1.5 }}>
        Cool, airy, modern. Frosted glass cards, generous radius, lavender tints. Feels calm and premium without being cold. Indigo accent is trustworthy and focused.
      </p>

      <div style={{ display: 'flex', gap: 24, marginBottom: 32, flexWrap: 'wrap' }}>
        <PaletteBlock title="Light Mode" colors={colors} />
        <PaletteBlock title="Dark Mode" colors={darkColors} />
      </div>

      <Section title="Type System">
        <TypeRow label="Display" family="'Outfit', sans-serif" size={36} weight={700} sample="Organic Chemistry" color="#2D2B3D" />
        <TypeRow label="Heading" family="'Outfit', sans-serif" size={20} weight={600} sample="Today's Review" color="#2D2B3D" />
        <TypeRow label="Body" family="'Outfit', sans-serif" size={15} weight={400} sample="You have 14 cards due across 3 decks. Your streak is 7 days." color="#55526A" />
        <TypeRow label="Mono" family="'Inter', sans-serif" size={13} weight={500} sample="82% mastery · 14:32 studied" color="#9994B0" />
      </Section>

      <Section title="Icon Style">
        <p style={{ fontSize: 14, color: '#9994B0', marginBottom: 8 }}>Rounded linear, 1.5px stroke. Soft and approachable.</p>
      </Section>

      <Section title="Signature Element">
        <p style={{ fontSize: 14, color: '#2D2B3D', lineHeight: 1.6 }}>
          <strong>Frosted glass cards</strong> with backdrop-blur and soft shadows. Cards feel like they float. Progress ring uses a smooth gradient from indigo → peach as mastery grows.
        </p>
        <div style={{ display: 'flex', gap: 10, marginTop: 14 }}>
          {[0.2, 0.5, 0.8].map((o, i) => (
            <div key={i} style={{
              width: 80, height: 50, borderRadius: 14,
              background: `rgba(91, 79, 196, ${0.06 + o * 0.08})`,
              border: '1px solid rgba(91, 79, 196, 0.1)',
              boxShadow: '0 4px 20px rgba(91, 79, 196, 0.06)',
            }} />
          ))}
        </div>
      </Section>
    </div>
  );
};

const SoftHomeScreen = () => (
  <IOSDevice screenTitle="" statusBarVariant="dark">
    <div style={{
      fontFamily: "'Outfit', sans-serif",
      background: '#F8F7FC',
      minHeight: '100%',
      padding: '16px 20px',
      color: '#2D2B3D',
    }}>
      <p style={{ fontSize: 13, color: '#9994B0', marginBottom: 2, fontWeight: 500 }}>Wednesday, April 23</p>
      <h1 style={{ fontSize: 28, fontWeight: 700, marginBottom: 18, letterSpacing: -0.3 }}>
        Good evening, Maya
      </h1>

      {/* Streak pill */}
      <div style={{
        display: 'inline-flex', alignItems: 'center', gap: 6,
        background: 'rgba(91,79,196,0.08)', borderRadius: 20, padding: '6px 14px', marginBottom: 18,
      }}>
        <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#5B4FC4' }} />
        <span style={{ fontSize: 13, fontWeight: 500, color: '#5B4FC4' }}>7 day streak</span>
      </div>

      {/* Cards due */}
      <div style={{
        background: 'rgba(91,79,196,0.06)', borderRadius: 18, padding: '20px',
        border: '1px solid rgba(91,79,196,0.08)', marginBottom: 14,
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
          <div>
            <p style={{ fontSize: 13, color: '#9994B0', fontWeight: 500, marginBottom: 2 }}>Due today</p>
            <p style={{ fontSize: 32, fontWeight: 700, color: '#5B4FC4' }}>14 <span style={{ fontSize: 15, fontWeight: 400, color: '#9994B0' }}>cards</span></p>
          </div>
          {/* Mini progress ring */}
          <svg width="52" height="52" viewBox="0 0 52 52">
            <circle cx="26" cy="26" r="22" fill="none" stroke="rgba(91,79,196,0.1)" strokeWidth="4" />
            <circle cx="26" cy="26" r="22" fill="none" stroke="url(#softGrad)" strokeWidth="4" strokeLinecap="round"
              strokeDasharray={`${0.6 * 138} ${138}`} transform="rotate(-90 26 26)" />
            <defs><linearGradient id="softGrad" x1="0" y1="0" x2="1" y2="1"><stop stopColor="#5B4FC4" /><stop offset="1" stopColor="#E8946A" /></linearGradient></defs>
          </svg>
        </div>
        <div style={{
          background: '#5B4FC4', borderRadius: 12, padding: '12px 18px', color: '#fff', fontSize: 15, fontWeight: 600, textAlign: 'center',
        }}>
          Start review
        </div>
      </div>

      {/* Continue */}
      <div style={{
        background: '#fff', borderRadius: 16, padding: '16px 18px', marginBottom: 14,
        border: '1px solid rgba(91,79,196,0.06)', boxShadow: '0 2px 12px rgba(91,79,196,0.04)',
      }}>
        <p style={{ fontSize: 11, fontWeight: 600, letterSpacing: 0.5, color: '#9994B0', marginBottom: 4 }}>CONTINUE</p>
        <p style={{ fontSize: 16, fontWeight: 600 }}>Organic Chemistry — Ch. 5</p>
        <p style={{ fontSize: 13, color: '#9994B0' }}>8 cards remaining · 4 min</p>
      </div>

      {/* Recent */}
      <p style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.8, color: '#9994B0', marginBottom: 10, marginTop: 6 }}>
        RECENT
      </p>
      {['Cell Biology Midterm', 'Linear Algebra — Ch. 3'].map((t, i) => (
        <div key={i} style={{
          background: '#fff', borderRadius: 14, padding: '14px 16px', marginBottom: 8,
          border: '1px solid rgba(91,79,196,0.06)',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        }}>
          <div>
            <p style={{ fontSize: 15, fontWeight: 500 }}>{t}</p>
            <p style={{ fontSize: 12, color: '#9994B0' }}>{['12 cards · Quiz ready', '8 cards · Podcast ready'][i]}</p>
          </div>
          <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M8 5l5 5-5 5" stroke="#9994B0" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </div>
      ))}

      {/* Bottom nav */}
      <div style={{
        display: 'flex', justifyContent: 'space-around', marginTop: 24, paddingTop: 12,
        borderTop: '1px solid #EEEDF5', color: '#9994B0', fontSize: 10, fontWeight: 500,
      }}>
        {['Home', 'Library', 'Study', 'Progress', 'Profile'].map((t, i) => (
          <div key={i} style={{ textAlign: 'center', color: i === 0 ? '#5B4FC4' : '#9994B0' }}>
            <div style={{ width: 22, height: 22, borderRadius: 11, background: i === 0 ? '#5B4FC4' : '#EEEDF5', margin: '0 auto 4px', opacity: i === 0 ? 0.15 : 0.5 }} />
            {t}
          </div>
        ))}
      </div>
    </div>
  </IOSDevice>
);

// ─── Direction 3: Nightowl ─────────────────────────────────────────
const NightPalette = () => {
  const colors = [
    { name: 'Midnight', hex: '#0F1523', dark: true },
    { name: 'Navy', hex: '#171E30', dark: true },
    { name: 'Slate', hex: '#2A3350', dark: true },
    { name: 'Muted', hex: '#6B7394', dark: true },
    { name: 'Amber', hex: '#E8A84C', dark: true },
    { name: 'Cyan', hex: '#4CC8E8', dark: false },
  ];
  const lightColors = [
    { name: 'Off White', hex: '#F4F3F0', dark: false },
    { name: 'Light Gray', hex: '#E8E7E3', dark: false },
    { name: 'Mid Gray', hex: '#9A9890', dark: false },
    { name: 'Dark', hex: '#1A1E2E', dark: true },
    { name: 'Amber', hex: '#D49540', dark: true },
    { name: 'Teal', hex: '#3AA8C4', dark: true },
  ];
  return (
    <div style={{ fontFamily: "'DM Sans', sans-serif", padding: 40, background: '#0F1523', width: '100%', height: '100%', color: '#E0DFE4' }}>
      <h2 style={{ fontFamily: "'JetBrains Mono', monospace", fontSize: 36, fontWeight: 700, marginBottom: 6, color: '#E8A84C' }}>
        Nightowl
      </h2>
      <p style={{ fontSize: 15, color: '#6B7394', marginBottom: 28, maxWidth: 460, lineHeight: 1.5 }}>
        Dark-first, bold, focused. Built for late-night study. Amber accent is warm and energizing against deep navy. Mono type for stats adds a data-forward feel.
      </p>

      <div style={{ display: 'flex', gap: 24, marginBottom: 32, flexWrap: 'wrap' }}>
        <PaletteBlock title="Dark Mode (Primary)" colors={colors} darkBg />
        <PaletteBlock title="Light Mode" colors={lightColors} />
      </div>

      <Section title="Type System" dark>
        <TypeRow label="Display" family="'DM Sans', sans-serif" size={36} weight={700} sample="Organic Chemistry" color="#E0DFE4" />
        <TypeRow label="Heading" family="'DM Sans', sans-serif" size={20} weight={600} sample="Today's Review" color="#E0DFE4" />
        <TypeRow label="Body" family="'DM Sans', sans-serif" size={15} weight={400} sample="You have 14 cards due across 3 decks. Your streak is 7 days." color="#8890A8" />
        <TypeRow label="Stats/Mono" family="'JetBrains Mono', monospace" size={13} weight={500} sample="82% mastery · 14:32 studied" color="#E8A84C" />
      </Section>

      <Section title="Icon Style" dark>
        <p style={{ fontSize: 14, color: '#6B7394', marginBottom: 8 }}>Filled style with subtle glow. Warm amber primary icons, cyan for secondary/info.</p>
      </Section>

      <Section title="Signature Element" dark>
        <p style={{ fontSize: 14, color: '#E0DFE4', lineHeight: 1.6 }}>
          <strong>Constellation heatmap</strong> — topics as dots on a dark grid, connected by faint lines. Brighter = higher mastery. Glowing <strong>progress ring</strong> with amber-to-cyan gradient.
        </p>
        <div style={{ display: 'flex', gap: 8, marginTop: 14, position: 'relative', padding: 10 }}>
          {[{ x: 0, y: 0, s: 0.9 }, { x: 40, y: -10, s: 0.5 }, { x: 80, y: 5, s: 0.8 }, { x: 115, y: -15, s: 0.3 }, { x: 155, y: 0, s: 1 }].map((d, i) => (
            <div key={i} style={{
              width: 12, height: 12, borderRadius: '50%',
              background: `oklch(${0.6 + d.s * 0.2} ${0.1 + d.s * 0.1} ${d.s > 0.5 ? 80 : 200})`,
              boxShadow: `0 0 ${6 + d.s * 10}px oklch(${0.6 + d.s * 0.2} ${0.1 + d.s * 0.1} ${d.s > 0.5 ? 80 : 200})`,
              position: 'absolute', left: d.x, top: 10 + d.y,
            }} />
          ))}
        </div>
      </Section>
    </div>
  );
};

const NightHomeScreen = () => (
  <IOSDevice screenTitle="" statusBarVariant="light" theme="dark">
    <div style={{
      fontFamily: "'DM Sans', sans-serif",
      background: '#0F1523',
      minHeight: '100%',
      padding: '16px 20px',
      color: '#E0DFE4',
    }}>
      <p style={{ fontSize: 13, color: '#6B7394', marginBottom: 2, fontWeight: 500 }}>Wednesday, April 23</p>
      <h1 style={{ fontSize: 28, fontWeight: 700, marginBottom: 18, letterSpacing: -0.3 }}>
        Good evening, Maya
      </h1>

      {/* Streak + due */}
      <div style={{ display: 'flex', gap: 10, marginBottom: 18 }}>
        <div style={{
          flex: 1, background: '#171E30', borderRadius: 14, padding: '14px 16px',
          border: '1px solid rgba(232,168,76,0.1)',
        }}>
          <p style={{ fontFamily: "'JetBrains Mono', monospace", fontSize: 24, fontWeight: 700, color: '#E8A84C' }}>7</p>
          <p style={{ fontSize: 12, color: '#6B7394' }}>day streak</p>
        </div>
        <div style={{
          flex: 1, background: '#171E30', borderRadius: 14, padding: '14px 16px',
          border: '1px solid rgba(76,200,232,0.1)',
        }}>
          <p style={{ fontFamily: "'JetBrains Mono', monospace", fontSize: 24, fontWeight: 700, color: '#4CC8E8' }}>14</p>
          <p style={{ fontSize: 12, color: '#6B7394' }}>cards due</p>
        </div>
      </div>

      {/* Continue */}
      <div style={{
        background: 'linear-gradient(135deg, #E8A84C, #D49540)', borderRadius: 16, padding: '18px 20px',
        color: '#0F1523', marginBottom: 16,
      }}>
        <p style={{ fontSize: 11, fontWeight: 600, letterSpacing: 0.5, opacity: 0.6, marginBottom: 4 }}>CONTINUE</p>
        <p style={{ fontSize: 17, fontWeight: 600, marginBottom: 2 }}>Organic Chemistry — Ch. 5</p>
        <p style={{ fontSize: 13, opacity: 0.7 }}>8 cards remaining · 4 min</p>
      </div>

      {/* Recent */}
      <p style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.8, color: '#6B7394', marginBottom: 10 }}>
        RECENT
      </p>
      {['Cell Biology Midterm', 'Linear Algebra — Ch. 3', 'Psych 101 Notes'].map((t, i) => (
        <div key={i} style={{
          background: '#171E30', borderRadius: 12, padding: '14px 16px', marginBottom: 8,
          border: '1px solid rgba(255,255,255,0.04)',
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        }}>
          <div>
            <p style={{ fontSize: 15, fontWeight: 500 }}>{t}</p>
            <p style={{ fontSize: 12, color: '#6B7394' }}>{['12 cards', '8 cards', '20 cards'][i]}</p>
          </div>
          <svg width="20" height="20" viewBox="0 0 20 20" fill="none"><path d="M8 5l5 5-5 5" stroke="#6B7394" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/></svg>
        </div>
      ))}

      {/* Bottom nav */}
      <div style={{
        display: 'flex', justifyContent: 'space-around', marginTop: 24, paddingTop: 12,
        borderTop: '1px solid #1E2538', color: '#6B7394', fontSize: 10, fontWeight: 500,
      }}>
        {['Home', 'Library', 'Study', 'Progress', 'Profile'].map((t, i) => (
          <div key={i} style={{ textAlign: 'center', color: i === 0 ? '#E8A84C' : '#6B7394' }}>
            <div style={{ width: 22, height: 22, borderRadius: 6, background: i === 0 ? 'rgba(232,168,76,0.15)' : '#1E2538', margin: '0 auto 4px' }} />
            {t}
          </div>
        ))}
      </div>
    </div>
  </IOSDevice>
);


// ─── Shared Components ──────────────────────────────────────────────
const PaletteBlock = ({ title, colors, darkBg }) => (
  <div>
    <p style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.5, marginBottom: 8, color: darkBg ? '#6B7394' : '#8C8577' }}>{title}</p>
    <div style={{ display: 'flex', gap: 6 }}>
      {colors.map((c, i) => (
        <div key={i} style={{ textAlign: 'center' }}>
          <div style={{
            width: 48, height: 48, borderRadius: 10, background: c.hex,
            border: `1px solid ${c.dark ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)'}`,
          }} />
          <p style={{ fontSize: 9, marginTop: 4, color: darkBg ? '#6B7394' : '#8C8577', fontWeight: 500 }}>{c.name}</p>
          <p style={{ fontSize: 8, color: darkBg ? '#4A5270' : '#AAA49A', fontFamily: 'monospace' }}>{c.hex}</p>
        </div>
      ))}
    </div>
  </div>
);

const Section = ({ title, children, dark }) => (
  <div style={{ marginBottom: 28 }}>
    <p style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.8, marginBottom: 10, color: dark ? '#6B7394' : '#8C8577' }}>
      {title.toUpperCase()}
    </p>
    {children}
  </div>
);

const TypeRow = ({ label, family, size, weight, sample, color }) => (
  <div style={{ marginBottom: 10 }}>
    <span style={{ fontSize: 10, fontWeight: 600, color: '#9994B0', letterSpacing: 0.5, display: 'inline-block', width: 60 }}>{label}</span>
    <span style={{ fontFamily: family, fontSize: size > 24 ? 24 : size, fontWeight: weight, color }}>{sample}</span>
  </div>
);


// ─── Canvas Layout ──────────────────────────────────────────────────
const App = () => (
  <DesignCanvas>
    <DCSection id="dir1" title="Direction 1 — Ink & Paper">
      <DCArtboard id="ink-palette" label="Palette & Type" width={560} height={660}>
        <InkPalette />
      </DCArtboard>
      <DCArtboard id="ink-home" label="Home Screen" width={375} height={812}>
        <InkHomeScreen />
      </DCArtboard>
    </DCSection>

    <DCSection id="dir2" title="Direction 2 — Soft Focus">
      <DCArtboard id="soft-palette" label="Palette & Type" width={560} height={660}>
        <SoftPalette />
      </DCArtboard>
      <DCArtboard id="soft-home" label="Home Screen" width={375} height={812}>
        <SoftHomeScreen />
      </DCArtboard>
    </DCSection>

    <DCSection id="dir3" title="Direction 3 — Nightowl">
      <DCArtboard id="night-palette" label="Palette & Type" width={560} height={700}>
        <NightPalette />
      </DCArtboard>
      <DCArtboard id="night-home" label="Home Screen" width={375} height={812}>
        <NightHomeScreen />
      </DCArtboard>
    </DCSection>
  </DesignCanvas>
);

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
