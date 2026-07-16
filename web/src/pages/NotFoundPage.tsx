import { ButtonLink, LearningTrace, useDocumentTitle } from '../components/ui';

export function NotFoundPage() {
  useDocumentTitle('Page not found');
  return (
    <section className="not-found">
      <LearningTrace />
      <p className="eyebrow">Lost path</p>
      <h1>This trace does not lead anywhere.</h1>
      <p>The page may have moved, or the address may be incomplete.</p>
      <ButtonLink className="primary" to="/">Return home</ButtonLink>
    </section>
  );
}
