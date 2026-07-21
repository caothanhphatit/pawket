# Pawket Mobile FE/UX Design V1
Status: Implementation-ready baseline  
Platform: Flutter, iOS and Android  
Scope: MVP through pets, media timeline, invitations, members, and reactions
## 1. Experience goal
Pawket is a private living archive for pets. The daily action is fast, but every action contributes to a long-lived pet profile. The interface MUST make the current pet context obvious, make switching pets effortless, and keep publishing a photo within a few deliberate steps.

Product principles:

- Pet-first: the pet, not the user account, is the primary visual identity.
- Quietly emotional: warm and memorable without childish pet-shop decoration.
- Camera-forward: capture is always one tap from primary navigation.
- Private by default: audience and membership are explicit, never implied.
- Progressive disclosure: name and species are enough to create a pet; detail can grow later.
- Honest state: uploads, offline data, permissions, and authorization changes are visible.
## 2. Visual direction
Direction name: `Field Notes`.

The app should feel like a well-kept pocket journal: large documentary photography, warm paper surfaces, ink-like typography, rounded labels, and small date annotations. It MUST avoid generic social-media chrome, bright marketplace colors, paw-print patterns, and excessive gradients.

- Photography owns the strongest visual area.
- Pet names use an expressive serif display face; controls use a clean humanist sans.
- Cards overlap subtly like mounted photographs, but layout remains predictable.
- Each pet MAY have an automatically assigned accent from an accessible palette. Accent is decorative; meaning never depends on it.
- Empty profiles use typographic initials and species silhouettes, so an avatar is never required.
## 3. Design tokens
Tokens are semantic and implemented through Flutter `ThemeExtension`; feature widgets MUST NOT hard-code values.

### Color

| Token | Light value | Purpose |
| --- | --- | --- |
| `canvas` | `#F7F2E8` | App background |
| `surface` | `#FFFDF8` | Cards, sheets, forms |
| `surfaceStrong` | `#EEE5D6` | Selected and grouped areas |
| `ink` | `#1F2925` | Primary text |
| `inkMuted` | `#66716C` | Secondary text |
| `brand` | `#C45132` | Primary action, camera shutter |
| `brandPressed` | `#963A25` | Pressed primary action |
| `leaf` | `#2E6B57` | Success, completed state |
| `sun` | `#D99A2B` | Warning, pending upload |
| `danger` | `#B53B35` | Destructive and error |
| `outline` | `#D7CCBC` | Borders and dividers |
| `scrim` | `#10151299` | Modal scrim |

All text/background combinations MUST meet WCAG AA. Dark theme is deferred, but semantic tokens MUST allow it later.

### Typography

- Display: `Fraunces` semibold, pet names and major empty-state statements.
- UI/body: `Atkinson Hyperlegible`, labels, body, forms, metadata.
- Display XL: 36/40; title: 28/32; heading: 22/28; body: 16/24; label: 14/20; caption: 12/16.
- Dynamic text MUST support at least 200 percent without clipping or losing actions.

### Layout and shape

- Spacing scale: `4, 8, 12, 16, 24, 32, 48`.
- Screen gutter: 20; compact gutter: 16; content max width on large devices: 640.
- Radius: 10 controls, 16 cards, 24 sheets, full pill for chips and avatars.
- Minimum touch target: 48 x 48 logical pixels.
- Elevation is restrained: border at rest, shadow only for floating capture and active sheets.

### Motion

- Fast 120 ms, standard 220 ms, emphasized 360 ms.
- Pet switching uses a 220 ms cross-fade plus 12 px horizontal drift in navigation direction.
- Successful publish uses a restrained thumbnail-to-timeline transition; no confetti.
- Upload progress never uses an indeterminate animation when byte progress is available.
- Respect reduced-motion settings by replacing movement with fades.
## 4. Information architecture and navigation
Authenticated primary navigation uses three destinations and one central action:
```text
Home            Capture            Memories            You
all/single feed floating action    pet timeline         account/settings
```
Rules:

- The pet context header appears on Home and Memories: `All pets` or the active pet.
- Tapping the header opens the pet switcher bottom sheet. Horizontal avatar chips provide direct switching when space permits.
- Capture opens above the current destination. From a single-pet context that pet is preselected; from All pets no pet is preselected.
- Back from the publish composer returns to preview without discarding the draft.
- Create/edit pet, members, invitation, post detail, and settings are pushed routes.
- Invitation deep links route through authentication, token validation, invitation preview, then acceptance.
- Route guards never infer access from local state; denied or removed access uses the backend result.
## 5. Screen inventory
| ID | Screen | Purpose | Primary action |
| --- | --- | --- | --- |
| A01 | Welcome | Explain lifetime profile value | Continue |
| A02 | Sign in | Managed OIDC entry | Sign in |
| A03 | First-pet empty state | Start useful onboarding | Create a pet |
| P01 | Create pet | Name and species, optional details/avatar | Create profile |
| P02 | Pet profile | Identity, summary, members, recent memories | Add memory |
| P03 | Edit pet | Update permitted pet fields | Save |
| P04 | Pet switcher sheet | Select All pets, pet, or add pet | Select context |
| H01 | All-pets Home | Combined recent posts and daily pet status | Capture today |
| H02 | Single-pet Home | Focused daily status and recent posts | Capture for pet |
| C01 | Capture source | Camera or library entry | Take/select photo |
| C02 | Media preview | Review, retake, crop/rotate if supported | Use photo |
| C03 | Publish composer | Tag pets, caption, audience, captured date | Publish |
| C04 | Upload/publish status | Show recoverable media workflow | Continue/retry |
| T01 | All-pets Memories | Combined cursor-paginated timeline | Open memory |
| T02 | Pet Memories | Lifetime timeline for one pet | Open memory |
| T03 | Post detail | Media, caption, pets, author, reactions | React |
| M01 | Members | List roles and current permissions | Invite member |
| M02 | Create invitation | Choose role and create secure link | Share invitation |
| M03 | Invitation preview | Show inviter, pet, role, expiry | Accept invitation |
| M04 | Invitation result | Confirm access or explain invalid state | View pet |
| U01 | You | Account, owned/accessible pets, settings | Open setting |
| U02 | Permissions/settings | Notifications, privacy links, logout | Update setting |

V1 supports image posts. Video controls may be hidden until backend limits and processing are approved.
## 6. Core flows
### 6.1 Onboarding and create pet

1. Welcome communicates `One profile. A lifetime of memories.`
2. User authenticates; app provisions or loads the internal account.
3. If accessible pet count is zero, show A03, not an empty feed.
4. P01 requires `name` and `species`; avatar, birth date/estimated date, gender, breed, home date, and bio are optional behind `Add details`.
5. Create uses an idempotency key and disables duplicate submission while pending.
6. On success, set the new pet active and open P02 with a first-memory prompt.
7. Validation remains inline; server conflict or unknown failure preserves all entered data.

### 6.2 Switch pet and All pets

1. User taps the pet context header or a visible pet chip.
2. P04 lists All pets first, then accessible pets, then Add pet.
3. Selection updates `activePetId`, closes the sheet, and refreshes only queries whose scope changed.
4. All pets combines authorized content and shows a compact `Today` row for each pet.
5. A single-pet context scopes profile, daily prompt, and timeline; capture pre-tags that pet.
6. The selection persists per signed-in user and falls back to All pets if access is removed.

### 6.3 Capture, tag, and publish

1. Capture action opens C01; request camera permission only after user chooses camera.
2. User takes one image or selects one from library. Remove EXIF GPS before upload.
3. C02 offers Retake/Choose another and Use photo.
4. C03 requires at least one accessible pet tag. Single-pet entry is preselected but editable.
5. Caption is optional. Audience defaults to `Pet members`; `Private` is available. `Friends` appears only when supported end-to-end.
6. App validates type/size, requests upload intent, uploads directly, completes media, then creates the post with an idempotency key.
7. Local preview remains visible during upload. Failure preserves the draft and offers Retry or Save locally; V1 does not silently queue offline publication.
8. Success opens the relevant timeline with the published item anchored at top.

### 6.4 Invitation and member access

1. Owner opens M01 from P02 and taps Invite member.
2. M02 chooses `Caretaker` or `Follower`, explains capabilities, and creates an expiring link.
3. The OS share sheet handles delivery; raw tokens are never displayed in logs or analytics.
4. Recipient deep link opens M03 after authentication and server validation.
5. M03 clearly states pet, inviter, requested role, and access granted.
6. Accept is idempotent. Success opens P02; expired, revoked, already-used, or forbidden invitations have distinct safe states.
7. Role or removal changes refresh permissions immediately and remove inaccessible cached data.
## 7. Core text wireframes
### All-pets Home
```text
+----------------------------------+
| Pawket                 [You]     |
| [All pets v]                     |
|                                  |
| TODAY                            |
| [Mit check] [Mo Add] [Dau Add]   |
|                                  |
| 18 JUL                           |
| +------------------------------+ |
| |          PHOTO               | |
| +------------------------------+ |
| Mit + Mo       by An      [heart]|
| "Window patrol."                |
|                                  |
| [Home]      (+)   [Memories][You]|
+----------------------------------+
```

### Pet switcher sheet
```text
+----------------------------------+
| Choose a view                    |
| [stack] All pets          [check]|
| [M] Mit       Dog                |
| [Mo] Mo       Cat                |
| [D] Dau       Dog                |
| -------------------------------- |
| [+] Add another pet              |
+----------------------------------+
```

### Create pet
```text
+----------------------------------+
| [Back] Create a pet              |
|          [Add photo]             |
| Name *        [______________]   |
| Species *     [Dog] [Cat]        |
| [v] Add details later            |
|                                  |
|          [Create profile]        |
+----------------------------------+
```

### Publish composer
```text
+----------------------------------+
| [Back] New memory                |
| [photo]  Captured today [Edit]   |
| Who is here? *                   |
| [Mit x] [Mo x] [+ Add pet]       |
| Caption [____________________]   |
| Audience [Pet members       v]   |
| Upload 64% [==========------]    |
|               [Publish]          |
+----------------------------------+
```

### Pet Memories
```text
+----------------------------------+
| [Mit v]                 [More]   |
| (M) Mit                         |
| Dog | Home since 2024            |
| 142 days remembered  [Members 3] |
|                                  |
| JULY 2026                        |
| [ large photo ] 18 Jul           |
| [photo] [photo] 12 Jul / 08 Jul  |
|                                  |
| [Home]      (+)   [Memories][You]|
+----------------------------------+
```
## 8. Component inventory
- `PetContextHeader`, `PetAvatar`, `PetChip`, `PetSwitcherSheet`.
- `PawketScaffold`, `PrimaryNavigation`, `CaptureFab`, `SectionHeader`.
- `MemoryCard`, `MemoryGridTile`, `DateRail`, `ReactionBar`, `AudienceBadge`.
- `DailyPetStatus`, `LifetimeSummary`, `MemberAvatarStack`, `RoleBadge`.
- `PrimaryButton`, `SecondaryButton`, `TextAction`, `DestructiveAction`.
- `PawketTextField`, `SpeciesSelector`, `PetMultiSelect`, `AudienceSelector`.
- `MediaPreview`, `UploadProgressCard`, `InlineRetry`, `PermissionPrompt`.
- `LoadingSkeleton`, `EmptyState`, `ErrorState`, `OfflineBanner`, `ToastNotice`.

Every reusable component defines content, loading/disabled, pressed/focused, error, high-text-scale, and screen-reader behavior.
## 9. State matrix
| Context | Loading | Empty | Error/offline | Recovery |
| --- | --- | --- | --- | --- |
| Pet bootstrap | Full-page branded progress | First-pet prompt | Safe error with correlation option | Retry/sign in |
| Home/timeline | Stable skeleton matching content | Contextual capture prompt | Cached content plus offline banner; otherwise error | Retry |
| Pet switcher | Row skeletons | Add first pet | Keep prior valid selection | Retry list |
| Create/edit pet | Button progress, fields retained | Not applicable | Inline validation or form-level safe error | Correct/retry |
| Camera/library | Native transition | No chosen media | Permission denied or unavailable device | Open settings/use library |
| Upload/publish | Preview plus byte progress | Not applicable | Stage-specific failure, draft retained | Retry/cancel/save draft |
| Members | Row skeletons | Owner-only invite prompt | Access removed, expired session, offline | Refresh/sign in |
| Invitation | Token validation progress | Not applicable | Expired/revoked/used/forbidden separately | Request new link/go Home |

Permission policy:

- Ask just in time and explain value before the OS dialog.
- Never block library use because camera is denied, or camera use because notifications are denied.
- Notification permission is requested after a meaningful action such as accepting an invite, not at first launch.
## 10. Accessibility and content
- Follow platform semantics, focus order, switch control, and screen-reader conventions.
- All icon-only controls require localized labels; pet avatars read as `Mit, dog, selected`.
- Images use author-provided caption as description when suitable; otherwise announce pet names and date without inventing visual content.
- Do not encode role, upload state, audience, or errors by color alone.
- Support large text, bold text, reduced motion, increased contrast, and landscape forms.
- Forms announce field errors and move focus to the first invalid field after submit.
- Destructive actions require explicit naming, for example `Remove Lan from Mit`, not `Confirm`.
- Strings are localization keys from V1. Avoid text embedded in images and layouts dependent on English length.
## 11. Flutter implementation mapping
Follow the feature-first architecture in `discussion/engineering/04-mobile-architecture.md`.
```text
features/auth            A01-A03, session redirects
features/pets            P01-P04, active pet selection
features/home            H01-H02, daily status composition
features/media           C01-C02, permissions and local media
features/posts           C03-C04, publish workflow and drafts
features/timeline        T01-T03, pagination and reactions
features/memberships     M01-M04, invitations and permissions
features/account         U01-U02
app/theme                tokens, type, motion, components theme
```
Implementation rules:

- Riverpod owns session, active pet, route-aware query state, and command controllers.
- `activePetId == null` means All pets; persist per user and validate after pet refresh.
- GoRouter uses typed/named routes and authentication/invitation guards.
- Presentation widgets render explicit sealed states: loading, content, empty, failure, offline.
- Repository interfaces isolate API and storage workflow. Widgets never call Dio or inspect raw problem responses.
- Publish is an application-level state machine: `draft -> requestingIntent -> uploading -> completing -> publishing -> published/failed`.
- Cursor pagination preserves existing items while loading the next page and deduplicates by opaque post ID.
- Permission-aware actions derive from backend permissions; hidden actions are not an authorization control.
- Cache is user-scoped. Logout or lost membership clears related media URLs, drafts containing private data, and inaccessible records.
- Widget tests cover zero/one/many pets, 200 percent text scale, permissions, all state variants, and role-aware actions.
- Golden tests are limited to tokens, pet switcher, memory card, composer, and core empty states on representative iOS and Android sizes.
## 12. V1 acceptance criteria
- A new user creates a pet without an image and reaches its profile without ambiguity.
- A user with at least three pets switches among each pet and All pets in two interactions or fewer.
- Capture from a single pet pre-tags that pet; capture from All pets requires explicit selection.
- Interrupted or failed publication never loses the local preview or caption during the active session.
- Timelines correctly represent one shared media item tagged to multiple pets.
- Owners can invite; caretakers and followers see only allowed actions.
- Core screens pass accessibility review at 200 percent text scale and with a screen reader.
- Every network-backed screen implements the state matrix before being considered complete.
