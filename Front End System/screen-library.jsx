/* Library Screen + Course Detail */

const LibraryScreen = ({ onNavigate }) => {
  const { theme } = useTheme();
  const { state } = useAppState();
  const [selectedCourse, setSelectedCourse] = React.useState(null);
  const [activeTab, setActiveTab] = React.useState('documents');

  const courses = [
    { id: 0, name: 'Organic Chemistry', color: '#E8A84C', docs: 4, decks: 3, quizzes: 2, podcasts: 1, lastAccess: '2h ago' },
    { id: 1, name: 'Cell Biology', color: '#4CC8E8', docs: 6, decks: 5, quizzes: 3, podcasts: 2, lastAccess: '1d ago' },
    { id: 2, name: 'Linear Algebra', color: '#5CB87A', docs: 3, decks: 2, quizzes: 1, podcasts: 0, lastAccess: '3d ago' },
    { id: 3, name: 'Psych 101', color: '#E85C5C', docs: 8, decks: 4, quizzes: 2, podcasts: 1, lastAccess: '5d ago' },
  ];

  const documents = [
    { name: 'Chapter 5 — Stereochemistry.pdf', pages: 42, assets: ['Flashcards', 'Quiz'] },
    { name: 'Lecture Notes Week 7.pdf', pages: 18, assets: ['Summary'] },
    { name: 'Problem Set 3.pdf', pages: 8, assets: [] },
    { name: 'Midterm Review Guide.docx', pages: 24, assets: ['Flashcards', 'Quiz', 'Podcast'] },
  ];

  const decks = [
    { name: 'Stereochemistry Basics', cards: 32, mastery: 72 },
    { name: 'Reaction Mechanisms', cards: 28, mastery: 45 },
    { name: 'Functional Groups', cards: 20, mastery: 88 },
  ];

  if (selectedCourse !== null) {
    const course = courses[selectedCourse];
    const tabs = ['documents', 'decks', 'quizzes', 'podcasts'];
    return (
      <div style={{ padding: `0 ${SPACING.xl}px ${SPACING.xxxl}px` }}>
        {/* Back header */}
        <div onClick={() => setSelectedCourse(null)} style={{
          display: 'flex', alignItems: 'center', gap: 6, padding: `${SPACING.lg}px 0`,
          cursor: 'pointer', color: theme.accent, fontSize: 14, fontWeight: 500,
        }}>
          <Icon name="chevronLeft" size={18} color={theme.accent} />
          Library
        </div>

        {/* Course header */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: SPACING.xl }}>
          <div style={{
            width: 48, height: 48, borderRadius: RADIUS.md,
            background: `${course.color}20`, display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <div style={{ width: 20, height: 20, borderRadius: 6, background: course.color }} />
          </div>
          <div>
            <h2 style={{ fontSize: 22, fontWeight: 700, color: theme.text, letterSpacing: -0.3 }}>{course.name}</h2>
            <p style={{ fontSize: 13, color: theme.textMuted }}>{course.docs} docs · {course.decks} decks · {course.quizzes} quizzes</p>
          </div>
        </div>

        {/* Segmented control */}
        <div style={{
          display: 'flex', background: theme.bgCard, borderRadius: RADIUS.md,
          padding: 3, marginBottom: SPACING.xl, border: `1px solid ${theme.border}`,
        }}>
          {tabs.map(tab => (
            <div key={tab} onClick={() => setActiveTab(tab)} style={{
              flex: 1, padding: '8px 0', textAlign: 'center', borderRadius: RADIUS.sm,
              fontSize: 13, fontWeight: activeTab === tab ? 600 : 400, cursor: 'pointer',
              background: activeTab === tab ? theme.accent : 'transparent',
              color: activeTab === tab ? '#0F1523' : theme.textMuted,
              transition: 'all 0.15s ease',
            }}>
              {tab.charAt(0).toUpperCase() + tab.slice(1)}
            </div>
          ))}
        </div>

        {/* Tab content */}
        {activeTab === 'documents' && (
          <div>
            {documents.map((doc, i) => (
              <Card key={i} style={{ marginBottom: SPACING.sm }}>
                <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                  <div style={{
                    width: 38, height: 44, borderRadius: 6, background: theme.accentSubtle,
                    display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                  }}>
                    <Icon name="doc" size={18} color={theme.accent} />
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <p style={{ fontSize: 14, fontWeight: 500, color: theme.text, marginBottom: 4, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{doc.name}</p>
                    <div style={{ display: 'flex', gap: 6, alignItems: 'center', flexWrap: 'wrap' }}>
                      <span style={{ fontSize: 12, color: theme.textMuted }}>{doc.pages} pages</span>
                      {doc.assets.map((a, j) => <Badge key={j} color={j === 0 ? 'accent' : 'secondary'}>{a}</Badge>)}
                      {doc.assets.length === 0 && (
                        <span style={{ fontSize: 12, color: theme.accent, fontWeight: 500, cursor: 'pointer' }}
                          onClick={() => onNavigate('upload')}>Generate →</span>
                      )}
                    </div>
                  </div>
                </div>
              </Card>
            ))}
            <div style={{ marginTop: SPACING.lg }}>
              <Button variant="secondary" fullWidth icon="upload" onClick={() => onNavigate('upload')}>
                Upload document
              </Button>
            </div>
          </div>
        )}

        {activeTab === 'decks' && (
          <div>
            {decks.map((deck, i) => (
              <Card key={i} onClick={() => onNavigate('study')} style={{ marginBottom: SPACING.sm }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                  <ProgressRing value={deck.mastery / 100} size={44} strokeWidth={3} />
                  <div style={{ flex: 1 }}>
                    <p style={{ fontSize: 15, fontWeight: 500, color: theme.text }}>{deck.name}</p>
                    <p style={{ fontSize: 12, color: theme.textMuted }}>{deck.cards} cards · {deck.mastery}% mastery</p>
                  </div>
                  <Icon name="chevronRight" size={18} color={theme.textMuted} />
                </div>
              </Card>
            ))}
          </div>
        )}

        {activeTab === 'quizzes' && (
          <div>
            {['Stereochemistry Quiz', 'Midterm Practice Exam'].map((q, i) => (
              <Card key={i} onClick={() => onNavigate('quiz')} style={{ marginBottom: SPACING.sm }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                  <div style={{
                    width: 44, height: 44, borderRadius: RADIUS.md, background: theme.secondarySubtle,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                  }}>
                    <Icon name="study" size={20} color={theme.secondary} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <p style={{ fontSize: 15, fontWeight: 500, color: theme.text }}>{q}</p>
                    <p style={{ fontSize: 12, color: theme.textMuted }}>{[15, 40][i]} questions · {['Practice', 'Timed'][i]}</p>
                  </div>
                  <Badge color={i === 0 ? 'success' : 'accent'}>{['88%', 'New'][i]}</Badge>
                </div>
              </Card>
            ))}
          </div>
        )}

        {activeTab === 'podcasts' && (
          <div>
            <Card onClick={() => onNavigate('podcast')} style={{ marginBottom: SPACING.sm }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
                <div style={{
                  width: 44, height: 44, borderRadius: RADIUS.md,
                  background: `linear-gradient(135deg, ${theme.accent}, ${theme.secondary})`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <Icon name="play" size={18} color="#0F1523" />
                </div>
                <div style={{ flex: 1 }}>
                  <p style={{ fontSize: 15, fontWeight: 500, color: theme.text }}>Stereochemistry Overview</p>
                  <p style={{ fontSize: 12, color: theme.textMuted }}>12:34 · Generated from Ch. 5</p>
                </div>
              </div>
            </Card>
          </div>
        )}
      </div>
    );
  }

  return (
    <div style={{ padding: `0 ${SPACING.xl}px ${SPACING.xxxl}px`, paddingTop: SPACING.lg }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: SPACING.xl }}>
        <h1 style={{ fontSize: 26, fontWeight: 700, color: theme.text, letterSpacing: -0.3 }}>Library</h1>
        <Button variant="ghost" size="sm" icon="plus" onClick={() => onNavigate('upload')}>New</Button>
      </div>

      <Input placeholder="Search courses..." icon="library" style={{ marginBottom: SPACING.xl }} />

      {courses.map((course, i) => (
        <Card key={i} onClick={() => setSelectedCourse(i)} style={{ marginBottom: SPACING.sm }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{
              width: 48, height: 48, borderRadius: RADIUS.md,
              background: `${course.color}18`, display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <div style={{ width: 18, height: 18, borderRadius: 5, background: course.color }} />
            </div>
            <div style={{ flex: 1 }}>
              <p style={{ fontSize: 16, fontWeight: 600, color: theme.text }}>{course.name}</p>
              <p style={{ fontSize: 12, color: theme.textMuted }}>
                {course.docs} docs · {course.decks} decks · {course.lastAccess}
              </p>
            </div>
            <Icon name="chevronRight" size={18} color={theme.textMuted} />
          </div>
        </Card>
      ))}
    </div>
  );
};

Object.assign(window, { LibraryScreen });
