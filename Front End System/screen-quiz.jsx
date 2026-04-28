/* Quiz Taking Flow */

const QuizScreen = ({ onNavigate }) => {
  const { theme } = useTheme();
  const [stage, setStage] = React.useState('intro'); // intro | taking | results
  const [qIdx, setQIdx] = React.useState(0);
  const [answers, setAnswers] = React.useState({});
  const [showExplanation, setShowExplanation] = React.useState(false);

  const questions = [
    { type: 'mcq', prompt: 'Which molecule is achiral?', options: ['2-bromobutane', 'Glycine', '2-chloropentane', 'Alanine'], correct: 1, topic: 'Chirality', explanation: 'Glycine has no chiral center — its alpha carbon has two hydrogen substituents.' },
    { type: 'true_false', prompt: 'Enantiomers have identical melting points.', correct: true, topic: 'Stereochemistry', explanation: 'Enantiomers share all scalar physical properties. Only optical rotation differs in sign.' },
    { type: 'fill_blank', prompt: 'A carbon bonded to four different groups is called a _____ center.', correct: 'chiral', topic: 'Nomenclature', explanation: 'Also known as a stereocenter or asymmetric center.' },
    { type: 'mcq', prompt: 'What is the relationship between D-glucose and L-glucose?', options: ['Diastereomers', 'Enantiomers', 'Constitutional isomers', 'Identical'], correct: 1, topic: 'Carbohydrates', explanation: 'D and L forms are non-superimposable mirror images — enantiomers.' },
    { type: 'short_answer', prompt: 'Explain why meso compounds are optically inactive despite having chiral centers.', topic: 'Stereochemistry', explanation: 'An internal mirror plane causes the optical rotations of the two halves to cancel.' },
  ];

  const q = questions[qIdx];
  const totalQ = questions.length;
  const answered = answers[qIdx] !== undefined;

  const submitAnswer = (ans) => {
    setAnswers(prev => ({ ...prev, [qIdx]: ans }));
    setShowExplanation(true);
  };

  const nextQ = () => {
    setShowExplanation(false);
    if (qIdx < totalQ - 1) setQIdx(qIdx + 1);
    else setStage('results');
  };

  const score = () => {
    let correct = 0;
    questions.forEach((q, i) => {
      if (q.type === 'mcq' && answers[i] === q.correct) correct++;
      if (q.type === 'true_false' && answers[i] === q.correct) correct++;
      if (q.type === 'fill_blank' && (answers[i] || '').toLowerCase().trim() === q.correct) correct++;
      if (q.type === 'short_answer' && answers[i]) correct += 0.5; // partial
    });
    return correct;
  };

  // ─── Intro ───
  if (stage === 'intro') {
    return (
      <div style={{ padding: `0 ${SPACING.xl}px`, paddingTop: SPACING.xxxl, textAlign: 'center' }}>
        <div style={{
          width: 72, height: 72, borderRadius: RADIUS.xl, margin: '0 auto 20px',
          background: `linear-gradient(135deg, ${theme.accent}, ${theme.secondary})`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="study" size={32} color="#0F1523" />
        </div>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: theme.text, marginBottom: 6 }}>Stereochemistry Quiz</h2>
        <p style={{ fontSize: 14, color: theme.textMuted, marginBottom: SPACING.xxl }}>
          {totalQ} questions · Practice mode · No time limit
        </p>
        <div style={{ display: 'flex', gap: 10, marginBottom: SPACING.xxl }}>
          {[
            { label: 'MCQ', count: 2 }, { label: 'T/F', count: 1 },
            { label: 'Fill-in', count: 1 }, { label: 'Short', count: 1 },
          ].map((t, i) => (
            <Card key={i} style={{ flex: 1, textAlign: 'center' }} padding={10}>
              <p style={{ fontFamily: FONT.mono, fontSize: 18, fontWeight: 700, color: theme.text }}>{t.count}</p>
              <p style={{ fontSize: 10, color: theme.textMuted }}>{t.label}</p>
            </Card>
          ))}
        </div>
        <Button fullWidth onClick={() => setStage('taking')}>Start quiz</Button>
        <div style={{ height: 10 }} />
        <Button variant="secondary" fullWidth onClick={() => onNavigate('study')}>Back</Button>
      </div>
    );
  }

  // ─── Results ───
  if (stage === 'results') {
    const s = score();
    const pct = Math.round((s / totalQ) * 100);
    return (
      <div style={{ padding: `0 ${SPACING.xl}px`, paddingTop: SPACING.xxl }}>
        <div style={{ textAlign: 'center', marginBottom: SPACING.xxl }}>
          <div style={{ position: 'relative', width: 100, height: 100, margin: '0 auto 16px' }}>
            <ProgressRing value={pct / 100} size={100} strokeWidth={6} />
            <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <span style={{ fontFamily: FONT.mono, fontSize: 28, fontWeight: 700, color: theme.accent }}>{pct}%</span>
            </div>
          </div>
          <h2 style={{ fontSize: 22, fontWeight: 700, color: theme.text, marginBottom: 4 }}>
            {pct >= 80 ? 'Great work' : pct >= 50 ? 'Good effort' : 'Keep practicing'}
          </h2>
          <p style={{ fontSize: 14, color: theme.textMuted }}>{s}/{totalQ} correct</p>
        </div>

        <SectionHeader>Breakdown by topic</SectionHeader>
        {['Chirality', 'Stereochemistry', 'Nomenclature', 'Carbohydrates'].map((t, i) => (
          <Card key={i} style={{ marginBottom: SPACING.sm }} padding={12}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: 14, color: theme.text, fontWeight: 500 }}>{t}</span>
              <Badge color={[true, false, true, true][i] ? 'success' : 'error'}>
                {[true, false, true, true][i] ? 'Correct' : 'Review'}
              </Badge>
            </div>
          </Card>
        ))}

        <div style={{ marginTop: SPACING.xl }}>
          <Button fullWidth onClick={() => onNavigate('study')}>Done</Button>
          <div style={{ height: 10 }} />
          <Button variant="secondary" fullWidth onClick={() => {
            setStage('intro'); setQIdx(0); setAnswers({}); setShowExplanation(false);
          }}>Retake quiz</Button>
        </div>
      </div>
    );
  }

  // ─── Taking ───
  return (
    <div style={{ padding: `0 ${SPACING.xl}px`, paddingTop: SPACING.lg, display: 'flex', flexDirection: 'column', minHeight: '100%' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: SPACING.lg }}>
        <div onClick={() => setStage('intro')} style={{ cursor: 'pointer' }}>
          <Icon name="close" size={20} color={theme.textMuted} />
        </div>
        <span style={{ fontSize: 13, color: theme.textMuted, fontFamily: FONT.mono }}>{qIdx + 1}/{totalQ}</span>
        <Badge color="accent">{q.topic}</Badge>
      </div>

      {/* Progress */}
      <div style={{ height: 3, borderRadius: 2, background: theme.border, marginBottom: SPACING.xxl, overflow: 'hidden' }}>
        <div style={{
          width: `${((qIdx + (answered ? 1 : 0)) / totalQ) * 100}%`,
          height: '100%', borderRadius: 2,
          background: `linear-gradient(90deg, ${theme.accent}, ${theme.secondary})`,
          transition: 'width 0.4s ease',
        }} />
      </div>

      {/* Question */}
      <p style={{ fontSize: 18, fontWeight: 600, color: theme.text, lineHeight: 1.5, marginBottom: SPACING.xxl }}>
        {q.prompt}
      </p>

      {/* Answer area */}
      {q.type === 'mcq' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {q.options.map((opt, i) => {
            const selected = answers[qIdx] === i;
            const isCorrect = i === q.correct;
            const showResult = showExplanation;
            return (
              <div key={i} onClick={() => !answered && submitAnswer(i)} style={{
                padding: '14px 16px', borderRadius: RADIUS.md, cursor: answered ? 'default' : 'pointer',
                background: showResult && isCorrect ? theme.successSubtle
                  : showResult && selected && !isCorrect ? theme.errorSubtle
                  : selected ? theme.accentSubtle : theme.bgCard,
                border: `1px solid ${showResult && isCorrect ? theme.success + '40'
                  : showResult && selected && !isCorrect ? theme.error + '40'
                  : selected ? theme.accent + '30' : theme.border}`,
                transition: 'all 0.2s ease',
                display: 'flex', alignItems: 'center', gap: 12,
              }}>
                <div style={{
                  width: 28, height: 28, borderRadius: '50%', flexShrink: 0,
                  border: `2px solid ${selected ? theme.accent : theme.border}`,
                  background: selected ? theme.accent : 'transparent',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  {selected && <Icon name="check" size={14} color="#0F1523" />}
                </div>
                <span style={{ fontSize: 15, color: theme.text, fontWeight: selected ? 500 : 400 }}>{opt}</span>
              </div>
            );
          })}
        </div>
      )}

      {q.type === 'true_false' && (
        <div style={{ display: 'flex', gap: 10 }}>
          {[true, false].map(val => {
            const selected = answers[qIdx] === val;
            const isCorrect = val === q.correct;
            const showResult = showExplanation;
            return (
              <div key={String(val)} onClick={() => !answered && submitAnswer(val)} style={{
                flex: 1, padding: '18px', borderRadius: RADIUS.md, textAlign: 'center',
                cursor: answered ? 'default' : 'pointer',
                background: showResult && isCorrect ? theme.successSubtle
                  : showResult && selected && !isCorrect ? theme.errorSubtle
                  : selected ? theme.accentSubtle : theme.bgCard,
                border: `1px solid ${showResult && isCorrect ? theme.success + '40' : selected ? theme.accent + '30' : theme.border}`,
                fontSize: 16, fontWeight: 600, color: theme.text, transition: 'all 0.2s ease',
              }}>
                {val ? 'True' : 'False'}
              </div>
            );
          })}
        </div>
      )}

      {q.type === 'fill_blank' && (
        <div>
          <Input placeholder="Type your answer..." value={answers[qIdx] || ''}
            onChange={v => !showExplanation && setAnswers(prev => ({ ...prev, [qIdx]: v }))} />
          {!showExplanation && answers[qIdx] && (
            <div style={{ marginTop: SPACING.lg }}>
              <Button fullWidth onClick={() => setShowExplanation(true)}>Submit</Button>
            </div>
          )}
        </div>
      )}

      {q.type === 'short_answer' && (
        <div>
          <div style={{
            background: theme.bgInput, borderRadius: RADIUS.md, border: `1px solid ${theme.border}`, padding: 14,
          }}>
            <textarea
              placeholder="Write your answer..."
              value={answers[qIdx] || ''}
              onChange={e => !showExplanation && setAnswers(prev => ({ ...prev, [qIdx]: e.target.value }))}
              style={{
                width: '100%', minHeight: 100, background: 'none', border: 'none', outline: 'none',
                color: theme.text, fontSize: 15, fontFamily: FONT.body, resize: 'vertical',
              }}
            />
          </div>
          <p style={{ fontSize: 12, color: theme.textMuted, marginTop: 6 }}>{(answers[qIdx] || '').length} characters</p>
          {!showExplanation && answers[qIdx] && (
            <div style={{ marginTop: SPACING.md }}>
              <Button fullWidth onClick={() => setShowExplanation(true)}>Submit</Button>
            </div>
          )}
        </div>
      )}

      {/* Explanation */}
      {showExplanation && (
        <Card style={{ marginTop: SPACING.xl, borderColor: theme.accent + '20' }}>
          <p style={{ fontSize: 12, fontWeight: 600, color: theme.accent, marginBottom: 6, letterSpacing: 0.5 }}>EXPLANATION</p>
          <p style={{ fontSize: 14, color: theme.textSecondary, lineHeight: 1.6 }}>{q.explanation}</p>
        </Card>
      )}

      {/* Next button */}
      {showExplanation && (
        <div style={{ marginTop: 'auto', paddingTop: SPACING.xl, paddingBottom: SPACING.xl }}>
          <Button fullWidth onClick={nextQ}>
            {qIdx < totalQ - 1 ? 'Next question' : 'See results'}
          </Button>
        </div>
      )}
    </div>
  );
};

Object.assign(window, { QuizScreen });
