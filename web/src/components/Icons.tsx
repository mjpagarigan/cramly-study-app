import type { SVGProps } from 'react';

type IconProps = SVGProps<SVGSVGElement>;

function IconBase({ children, ...props }: IconProps) {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" focusable="false" {...props}>
      {children}
    </svg>
  );
}

export const HomeIcon = (props: IconProps) => (
  <IconBase {...props}><path d="M4 11 12 4l8 7M6 10v10h12V10" /></IconBase>
);
export const LibraryIcon = (props: IconProps) => (
  <IconBase {...props}><path d="M5 4h12a2 2 0 0 1 2 2v14H7a2 2 0 0 1-2-2zM7 16h12" /></IconBase>
);
export const StudyIcon = (props: IconProps) => (
  <IconBase {...props}><rect x="4" y="5" width="16" height="14" rx="2" /><path d="m10 9 5 3-5 3z" /></IconBase>
);
export const ProgressIcon = (props: IconProps) => (
  <IconBase {...props}><path d="M5 19V9M12 19V5M19 19v-7" /></IconBase>
);
export const MenuIcon = (props: IconProps) => (
  <IconBase {...props}><path d="M4 7h16M4 12h16M4 17h16" /></IconBase>
);
export const CloseIcon = (props: IconProps) => (
  <IconBase {...props}><path d="m6 6 12 12M18 6 6 18" /></IconBase>
);
export const SearchIcon = (props: IconProps) => (
  <IconBase {...props}><circle cx="11" cy="11" r="6" /><path d="m16 16 4 4" /></IconBase>
);
export const PlusIcon = (props: IconProps) => (
  <IconBase {...props}><path d="M12 5v14M5 12h14" /></IconBase>
);
export const ArrowLeftIcon = (props: IconProps) => (
  <IconBase {...props}><path d="m15 5-7 7 7 7" /></IconBase>
);
export const ArrowRightIcon = (props: IconProps) => (
  <IconBase {...props}><path d="m9 5 7 7-7 7" /></IconBase>
);
export const UploadIcon = (props: IconProps) => (
  <IconBase {...props}><path d="M12 16V4m0 0L7 9m5-5 5 5M5 14v5h14v-5" /></IconBase>
);
export const FileIcon = (props: IconProps) => (
  <IconBase {...props}><path d="M6 3h8l4 4v14H6zM14 3v5h5" /></IconBase>
);
export const EditIcon = (props: IconProps) => (
  <IconBase {...props}><path d="m4 20 4-1 11-11-3-3L5 16zM14 7l3 3" /></IconBase>
);
export const TrashIcon = (props: IconProps) => (
  <IconBase {...props}><path d="M4 7h16M9 7V4h6v3M7 7l1 13h8l1-13M10 11v5M14 11v5" /></IconBase>
);
export const CopyIcon = (props: IconProps) => (
  <IconBase {...props}><rect x="8" y="8" width="11" height="11" rx="1" /><path d="M16 8V5H5v11h3" /></IconBase>
);
export const LogOutIcon = (props: IconProps) => (
  <IconBase {...props}><path d="M10 5H5v14h5M14 8l4 4-4 4M18 12H9" /></IconBase>
);
export const ChevronRightIcon = (props: IconProps) => (
  <IconBase {...props}><path d="m9 5 7 7-7 7" /></IconBase>
);
export const GoogleIcon = (props: IconProps) => (
  <IconBase {...props}><path d="M20 12.2c0-.7-.1-1.4-.2-2H12v3.7h4.5a3.9 3.9 0 0 1-1.7 2.5v2.4h3c1.8-1.6 2.2-4 2.2-6.6Z" /><path d="M12 20c2.2 0 4.1-.7 5.5-2l-2.7-2.1c-.7.5-1.7.8-2.8.8-2.1 0-4-1.4-4.6-3.4H4.6v2.2A8.3 8.3 0 0 0 12 20Z" /><path d="M7.4 13.3A5 5 0 0 1 7.1 12c0-.5.1-.9.3-1.3V8.5H4.6A8.2 8.2 0 0 0 3.7 12c0 1.3.3 2.5.9 3.5l2.8-2.2Z" /><path d="M12 7.3c1.2 0 2.3.4 3.2 1.2l2.4-2.4A8 8 0 0 0 4.6 8.5l2.8 2.2c.6-2 2.5-3.4 4.6-3.4Z" /></IconBase>
);
export const RefreshIcon = (props: IconProps) => (
  <IconBase {...props}><path d="M19 8a7 7 0 1 0 1 6M19 4v4h-4" /></IconBase>
);
