import type { AsyncJob, Course, Deck, DeckCard, Document, Summary } from '../types';

export const demoMode = import.meta.env.DEV && import.meta.env.VITE_DEMO_MODE === 'true';
const now = new Date();
const yesterday = new Date(Date.now() - 86_400_000);

export const demoCourses: Course[] = [{
  id: 'demo-course',
  name: 'Cell Biology',
  color: '#477966',
  icon: null,
  documentCount: 1,
  deckCount: 2,
  quizCount: 0,
  createdAt: yesterday,
  updatedAt: now,
}];

export const demoDocuments: Document[] = [{
  id: 'demo-document',
  courseId: 'demo-course',
  sourceType: 'pdf',
  title: 'Cellular respiration notes',
  status: 'ready',
  fileName: 'cellular-respiration.pdf',
  fileSize: 2_516_582,
  mimeType: 'application/pdf',
  storagePath: null,
  sourceUrl: null,
  pageCount: 18,
  wordCount: 3842,
  extractedTextPath: 'demo://extracted-text',
  errorMessage: null,
  generatedAssets: {
    deckIds: ['demo-deck'],
    quizIds: [],
    summaryIds: ['demo-summary'],
    studyGuideIds: [],
    podcastIds: [],
  },
  uploadedAt: now,
  extractedAt: now,
  extractionJobId: null,
}];

export const demoDecks: Deck[] = [
  {
    id: 'demo-deck',
    courseId: 'demo-course',
    sourceDocumentId: 'demo-document',
    title: 'Cell respiration',
    description: 'The pathway from glucose to ATP.',
    cardCount: 3,
    generationMethod: 'ai',
    status: 'ready',
    jobId: null,
    errorMessage: null,
    createdAt: now,
    updatedAt: now,
  },
  {
    id: 'demo-manual-deck',
    courseId: 'demo-course',
    sourceDocumentId: null,
    title: 'Membrane transport',
    description: 'Saved questions from course notes.',
    cardCount: 2,
    generationMethod: 'manual',
    status: 'ready',
    jobId: null,
    errorMessage: null,
    createdAt: yesterday,
    updatedAt: yesterday,
  },
];

export const demoCards: Record<string, DeckCard[]> = {
  'demo-deck': [
    { id: 'card-1', front: 'Where does glycolysis occur?', back: 'In the cytosol, where glucose begins breaking down.', hint: 'Think about the part of the cell outside the mitochondrion.', explanation: 'Glycolysis does not require a mitochondrial compartment.', topic: 'Glycolysis', srs: { easeFactor: 2.5, interval: 0, repetitions: 0, nextReviewDate: null, lastReviewedAt: null }, stats: { timesShown: 0, timesCorrect: 0, timesWrong: 0 }, createdAt: yesterday },
    { id: 'card-2', front: 'What does the citric acid cycle produce?', back: 'Electron carriers, carbon dioxide, and a small amount of ATP.', hint: 'Focus on NADH and FADH2.', explanation: 'Those carriers move high-energy electrons to the electron transport chain.', topic: 'Citric acid cycle', srs: { easeFactor: 2.5, interval: 0, repetitions: 0, nextReviewDate: null, lastReviewedAt: null }, stats: { timesShown: 0, timesCorrect: 0, timesWrong: 0 }, createdAt: now },
    { id: 'card-3', front: 'What drives ATP synthase?', back: 'A proton gradient across the inner mitochondrial membrane.', hint: 'Consider chemiosmosis.', explanation: 'Protons flowing down the gradient rotate ATP synthase.', topic: 'Oxidative phosphorylation', srs: { easeFactor: 2.5, interval: 0, repetitions: 0, nextReviewDate: null, lastReviewedAt: null }, stats: { timesShown: 0, timesCorrect: 0, timesWrong: 0 }, createdAt: now },
  ],
  'demo-manual-deck': [],
};

export const demoSummaries: Summary[] = [{
  id: 'demo-summary',
  courseId: 'demo-course',
  sourceDocumentId: 'demo-document',
  depth: 'detailed',
  status: 'ready',
  content: `## The main idea\n\nCellular respiration converts energy stored in nutrients into ATP, the molecule cells use to power work.\n\n## Three connected stages\n\n- **Glycolysis** splits glucose into pyruvate and produces ATP and NADH.\n- **The citric acid cycle** oxidizes acetyl-CoA and transfers electrons to NADH and FADH2.\n- **Oxidative phosphorylation** creates a proton gradient that drives ATP synthase.\n\n## What to remember\n\nThe largest ATP yield comes from oxidative phosphorylation. Oxygen is the final electron acceptor.`,
  jobId: null,
  errorMessage: null,
  createdAt: now,
  updatedAt: now,
}];

export const demoJobs: AsyncJob[] = [];

export const demoExtractedText = `Cellular respiration is the set of metabolic reactions cells use to convert biochemical energy from nutrients into ATP. Glycolysis begins in the cytosol, while the citric acid cycle and oxidative phosphorylation occur in the mitochondria.

During glycolysis, one glucose molecule is split into two pyruvate molecules. The process produces a small amount of ATP and transfers electrons to NADH.

The citric acid cycle continues the oxidation of carbon compounds. NADH and FADH2 carry high-energy electrons to the electron transport chain, where a proton gradient drives ATP synthase.`;
