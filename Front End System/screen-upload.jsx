/* Upload / Create Flow */

const UploadScreen = ({ onNavigate }) => {
  const { theme } = useTheme();
  const [step, setStep] = React.useState('source'); // source | generate | assign | processing | done
  const [files, setFiles] = React.useState([]);
  const [generators, setGenerators] = React.useState({ flashcards: true, quiz: false, summary: true, studyGuide: false, podcast: false });
  const [progress, setProgress] = React.useState(0);
  const [jobs, setJobs] = React.useState([]);

  const fileTypes = [
    { icon: 'doc', label: 'PDF', ext: '.pdf' },
    { icon: 'doc', label: 'DOCX', ext: '.docx' },
    { icon: 'doc', label: 'PPTX', ext: '.pptx' },
    { icon: 'upload', label: 'Image', ext: '.png' },
    { icon: 'play', label: 'YouTube', ext: 'URL' },
    { icon: 'podcast', label: 'Audio', ext: '.mp3' },
  ];

  const generatorOptions = [
    { key: 'flashcards', label: 'Flashcards', desc: '~30 cards', time: '~1 min', icon: 'flash' },
    { key: 'quiz', label: 'Practice Quiz', desc: '15 questions', time: '~1 min', icon: 'study' },
    { key: 'summary', label: 'Summary', desc: '3 depth levels', time: '~30s', icon: 'doc' },
    { key: 'studyGuide', label: 'Study Guide', desc: 'Structured notes', time: '~1 min', icon: 'doc' },
    { key: 'podcast', label: 'Podcast', desc: '2 speakers, ~10 min', time: '~3 min', icon: 'podcast' },
  ];

  const startProcessing = () => {
    setStep('processing');
    const selected = Object.entries(generators).filter(([, v]) => v).map(([k]) => k);
    const allJobs = [{ id: 'extract', label: 'Extracting text', status: 'processing' },
      ...selected.map(k => ({ id: k, label: `Generating ${k}`, status: 'queued' }))];
    setJobs(allJobs);

    let i = 0;
    const tick = () => {
      if (i >= allJobs.length) { setStep('done'); return; }
      setJobs(prev => prev.map((j, idx) => ({
        ...j,
        status: idx < i ? 'done' : idx === i ? 'processing' : 'queued'
      })));
      setProgress(((i + 0.5) / allJobs.length) * 100);
      i++;
      setTimeout(tick, 1200);
    };
    setTimeout(tick, 400);
  };

  // ─── Source selection ───
  if (step === 'source') {
    return (
      <div style={{ padding: `0 ${SPACING.xl}px`, paddingTop: SPACING.lg }}>
        <h1 style={{ fontSize: 26, fontWeight: 700, color: theme.text, marginBottom: 6, letterSpacing: -0.3 }}>Upload</h1>
        <p style={{ fontSize: 14, color: theme.textMuted, marginBottom: SPACING.xxl }}>Add study materials to generate from</p>

        {/* Drop zone */}
        <div style={{
          border: `2px dashed ${theme.border}`, borderRadius: RADIUS.xl,
          padding: `${SPACING.xxxl}px ${SPACING.xl}px`, textAlign: 'center', marginBottom: SPACING.xl,
          background: theme.bgCard, cursor: 'pointer',
        }} onClick={() => setFiles([{ name: 'Chapter 5 — Stereochemistry.pdf', size: '2.4 MB', pages: 42 }])}>
          <div style={{
            width: 56, height: 56, borderRadius: RADIUS.lg, background: theme.accentSubtle,
            display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 14px',
          }}>
            <Icon name="upload" size={24} color={theme.accent} />
          </div>
          <p style={{ fontSize: 15, fontWeight: 500, color: theme.text, marginBottom: 4 }}>Tap to upload files</p>
          <p style={{ fontSize: 13, color: theme.textMuted }}>PDF, DOCX, PPTX, images, audio</p>
        </div>

        {/* File type grid */}
        <SectionHeader>Or add from</SectionHeader>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8, marginBottom: SPACING.xl }}>
          {fileTypes.map((ft, i) => (
            <Card key={i} onClick={() => setFiles([{ name: 'Chapter 5 — Stereochemistry.pdf', size: '2.4 MB', pages: 42 }])}
              style={{ textAlign: 'center', cursor: 'pointer' }} padding={14}>
              <Icon name={ft.icon} size={20} color={theme.accent} style={{ margin: '0 auto 6px' }} />
              <p style={{ fontSize: 13, fontWeight: 500, color: theme.text }}>{ft.label}</p>
              <p style={{ fontSize: 11, color: theme.textMuted }}>{ft.ext}</p>
            </Card>
          ))}
        </div>

        {/* Selected files */}
        {files.length > 0 && (
          <div>
            <SectionHeader>Selected</SectionHeader>
            {files.map((f, i) => (
              <Card key={i} style={{ marginBottom: SPACING.sm }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <div style={{ width: 38, height: 44, borderRadius: 6, background: theme.accentSubtle, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Icon name="doc" size={18} color={theme.accent} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <p style={{ fontSize: 14, fontWeight: 500, color: theme.text }}>{f.name}</p>
                    <p style={{ fontSize: 12, color: theme.textMuted }}>{f.size} · {f.pages} pages</p>
                  </div>
                  <div onClick={() => setFiles([])} style={{ cursor: 'pointer' }}>
                    <Icon name="close" size={18} color={theme.textMuted} />
                  </div>
                </div>
              </Card>
            ))}
            <div style={{ marginTop: SPACING.lg }}>
              <Button fullWidth onClick={() => setStep('generate')}>Continue</Button>
            </div>
          </div>
        )}
      </div>
    );
  }

  // ─── Generator picker ───
  if (step === 'generate') {
    return (
      <div style={{ padding: `0 ${SPACING.xl}px`, paddingTop: SPACING.lg }}>
        <div onClick={() => setStep('source')} style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer', color: theme.accent, fontSize: 14, fontWeight: 500, marginBottom: SPACING.lg }}>
          <Icon name="chevronLeft" size={18} color={theme.accent} /> Back
        </div>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: theme.text, marginBottom: 6 }}>What to generate?</h2>
        <p style={{ fontSize: 14, color: theme.textMuted, marginBottom: SPACING.xl }}>Pick what you need from this document</p>

        {generatorOptions.map(opt => {
          const active = generators[opt.key];
          return (
            <div key={opt.key} onClick={() => setGenerators(prev => ({ ...prev, [opt.key]: !prev[opt.key] }))}
              style={{
                display: 'flex', alignItems: 'center', gap: 14, padding: 16, marginBottom: 8,
                background: active ? theme.accentSubtle : theme.bgCard,
                border: `1px solid ${active ? theme.accent + '30' : theme.border}`,
                borderRadius: RADIUS.lg, cursor: 'pointer', transition: 'all 0.15s ease',
              }}>
              <div style={{
                width: 44, height: 44, borderRadius: RADIUS.md,
                background: active ? theme.accent + '20' : theme.bgElevated,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name={opt.icon} size={20} color={active ? theme.accent : theme.textMuted} />
              </div>
              <div style={{ flex: 1 }}>
                <p style={{ fontSize: 15, fontWeight: 500, color: theme.text }}>{opt.label}</p>
                <p style={{ fontSize: 12, color: theme.textMuted }}>{opt.desc} · {opt.time}</p>
              </div>
              <div style={{
                width: 24, height: 24, borderRadius: 6, border: `2px solid ${active ? theme.accent : theme.border}`,
                background: active ? theme.accent : 'transparent',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {active && <Icon name="check" size={14} color="#0F1523" />}
              </div>
            </div>
          );
        })}

        <div style={{ marginTop: SPACING.xl }}>
          <Button fullWidth onClick={() => setStep('assign')}>
            Continue
          </Button>
        </div>
      </div>
    );
  }

  // ─── Course assignment ───
  if (step === 'assign') {
    const courses = ['Organic Chemistry', 'Cell Biology', 'Linear Algebra', 'Psych 101'];
    const [selected, setSelected] = React.useState(0);
    return (
      <div style={{ padding: `0 ${SPACING.xl}px`, paddingTop: SPACING.lg }}>
        <div onClick={() => setStep('generate')} style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer', color: theme.accent, fontSize: 14, fontWeight: 500, marginBottom: SPACING.lg }}>
          <Icon name="chevronLeft" size={18} color={theme.accent} /> Back
        </div>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: theme.text, marginBottom: 6 }}>Assign to course</h2>
        <p style={{ fontSize: 14, color: theme.textMuted, marginBottom: SPACING.xl }}>Where should this material live?</p>

        {courses.map((c, i) => (
          <Card key={i} onClick={() => setSelected(i)}
            style={{ marginBottom: SPACING.sm, borderColor: selected === i ? theme.accent + '30' : theme.border, background: selected === i ? theme.accentSubtle : theme.bgCard }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ width: 12, height: 12, borderRadius: '50%', background: ['#E8A84C','#4CC8E8','#5CB87A','#E85C5C'][i] }} />
              <span style={{ fontSize: 15, fontWeight: selected === i ? 600 : 400, color: theme.text }}>{c}</span>
            </div>
          </Card>
        ))}

        <Card onClick={() => {}} style={{ marginBottom: SPACING.xl, borderStyle: 'dashed' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, justifyContent: 'center' }}>
            <Icon name="plus" size={18} color={theme.accent} />
            <span style={{ fontSize: 14, color: theme.accent, fontWeight: 500 }}>Create new course</span>
          </div>
        </Card>

        <Button fullWidth onClick={startProcessing}>Start generating</Button>
      </div>
    );
  }

  // ─── Processing ───
  if (step === 'processing') {
    return (
      <div style={{ padding: `0 ${SPACING.xl}px`, paddingTop: SPACING.xxxl, textAlign: 'center' }}>
        <div style={{ position: 'relative', width: 80, height: 80, margin: '0 auto 20px' }}>
          <ProgressRing value={progress / 100} size={80} strokeWidth={5} />
          <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <span style={{ fontFamily: FONT.mono, fontSize: 18, fontWeight: 700, color: theme.accent }}>{Math.round(progress)}%</span>
          </div>
        </div>
        <h2 style={{ fontSize: 20, fontWeight: 700, color: theme.text, marginBottom: 4 }}>Processing</h2>
        <p style={{ fontSize: 14, color: theme.textMuted, marginBottom: SPACING.xxl }}>This usually takes a minute or two</p>

        {/* Job timeline */}
        <div style={{ textAlign: 'left' }}>
          {jobs.map((job, i) => (
            <div key={job.id} style={{ display: 'flex', gap: 14, marginBottom: 4 }}>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', width: 20 }}>
                <div style={{
                  width: 20, height: 20, borderRadius: '50%', flexShrink: 0,
                  background: job.status === 'done' ? theme.success : job.status === 'processing' ? theme.accent : theme.bgCard,
                  border: `2px solid ${job.status === 'done' ? theme.success : job.status === 'processing' ? theme.accent : theme.border}`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  boxShadow: job.status === 'processing' ? `0 0 10px ${theme.accent}40` : 'none',
                }}>
                  {job.status === 'done' && <Icon name="check" size={12} color="#fff" />}
                  {job.status === 'processing' && <div style={{ width: 6, height: 6, borderRadius: '50%', background: '#0F1523' }} />}
                </div>
                {i < jobs.length - 1 && <div style={{ width: 2, flex: 1, background: job.status === 'done' ? theme.success : theme.border, minHeight: 20 }} />}
              </div>
              <div style={{ paddingBottom: 16 }}>
                <p style={{ fontSize: 14, fontWeight: 500, color: job.status === 'queued' ? theme.textMuted : theme.text }}>{job.label}</p>
                <p style={{ fontSize: 12, color: theme.textMuted }}>
                  {job.status === 'done' ? 'Complete' : job.status === 'processing' ? 'In progress...' : 'Waiting'}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  // ─── Done ───
  return (
    <div style={{ padding: `0 ${SPACING.xl}px`, paddingTop: SPACING.xxxl, textAlign: 'center' }}>
      <div style={{
        width: 72, height: 72, borderRadius: '50%', background: theme.successSubtle,
        display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 20px',
      }}>
        <Icon name="check" size={32} color={theme.success} />
      </div>
      <h2 style={{ fontSize: 22, fontWeight: 700, color: theme.text, marginBottom: 6 }}>All done</h2>
      <p style={{ fontSize: 14, color: theme.textMuted, marginBottom: SPACING.xxl }}>Your study materials are ready</p>

      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', justifyContent: 'center', marginBottom: SPACING.xxl }}>
        {Object.entries(generators).filter(([, v]) => v).map(([k]) => (
          <Badge key={k} color="success">{k}</Badge>
        ))}
      </div>

      <Button fullWidth onClick={() => onNavigate('library')}>View in library</Button>
      <div style={{ height: 10 }} />
      <Button variant="secondary" fullWidth onClick={() => { setStep('source'); setFiles([]); setProgress(0); }}>Upload more</Button>
    </div>
  );
};

Object.assign(window, { UploadScreen });
