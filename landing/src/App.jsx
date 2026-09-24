import { useEffect, useRef, useState } from 'react';
import appIcon from '../assets/app-icon.png';
import albyHappy from '../assets/mascot/alby-happy.png';
import albyOfficer from '../assets/mascot/alby-officer.png';
import alarmScreen from '../screens/1.png';
import reasonScreen from '../screens/4.png';
import verificationScreen from '../screens/2.png';
import appealScreen from '../screens/7.png';
import wakeCheckScreen from '../screens/9.png';
import successScreen from '../screens/10.png';

const APP_URL = 'https://kya-iota.vercel.app/';

const features = [
  {
    icon: 'button',
    iconClass: 'icon-red',
    title: 'Dodging Snooze Button',
    copy: 'We hide, move, and make it harder to snooze. Like a real commitment to your future self.',
  },
  {
    icon: 'file',
    iconClass: 'icon-yellow',
    title: 'Reason-for-Snoozing Form',
    copy: 'Fill out a detailed form explaining why you need more sleep. Good luck.',
  },
  {
    icon: 'officer',
    iconClass: 'icon-gold',
    title: 'AI Snooze Officer',
    copy: 'Our AI officer reviews your request with zero sympathy and maximum bureaucracy.',
  },
  {
    icon: 'puzzle',
    iconClass: 'icon-green',
    title: 'Wakefulness CAPTCHA',
    copy: 'Prove you’re human—and awake—with challenges that turn your snooze into a puzzle.',
  },
  {
    icon: 'folder',
    iconClass: 'icon-yellow',
    title: 'Bureaucratic Processing',
    copy: 'Your request is filed, reviewed, and almost always rejected.',
  },
  {
    icon: 'scan',
    iconClass: 'icon-blue',
    title: 'Identity Wake Check',
    copy: 'Take a live selfie to confirm it’s really you. No impostors. No more fake snoozes.',
  },
];

const steps = [
  {
    number: '01',
    label: 'Ring',
    title: 'Ring',
    copy: 'Your alarm goes off. The journey begins.',
    screen: alarmScreen,
    color: 'pink',
  },
  {
    number: '02',
    label: 'Request',
    title: 'Request',
    copy: 'File a snooze request with a detailed justification.',
    screen: reasonScreen,
    color: 'blue',
  },
  {
    number: '03',
    label: 'Get Rejected',
    title: 'Get Rejected',
    copy: 'Our AI Snooze Officer reviews your request. Spoiler: it’s probably a no.',
    screen: appealScreen,
    color: 'gold',
  },
  {
    number: '04',
    label: 'Verify',
    title: 'Verify',
    copy: 'Complete a wakefulness challenge and identity check.',
    screen: wakeCheckScreen,
    color: 'purple',
  },
  {
    number: '05',
    label: 'Awake',
    title: 'Awake',
    copy: 'You’re up. Somehow, it was easier than another snooze.',
    screen: successScreen,
    color: 'green',
  },
];

const testimonials = [
  {
    caseNumber: 'Case #KYA-1042',
    quote: 'KYA has officially ended my 2-hour snooze habit. I hate it. It’s perfect.',
    name: 'Jamie L.',
    status: 'Approved',
  },
  {
    caseNumber: 'Case #KYA-6873',
    quote: 'At first I was annoyed. Now I’m an early riser. Alby is scarier than my boss.',
    name: 'Taylor M.',
    status: 'Approved',
  },
  {
    caseNumber: 'Case #KYA-2198',
    quote: 'I’m still trying to find a good reason to snooze. So far, 0/10 success rate.',
    name: 'Morgan K.',
    status: 'Pending',
  },
];

const faqs = [
  ['Is KYA really free to try?', 'Yes. The demo is free to run, and no account is required.'],
  ['What happens if my snooze request is approved?', 'You receive one strictly authorized snooze period before the alarm returns.'],
  ['Do you store my photos or personal data?', 'No. The live wake check stays on your device and is not recorded, uploaded, or stored.'],
  ['Can I customize the challenges?', 'The current demo uses a fixed compliance flow designed to make waking up easier than continuing.'],
  ['Will this actually help me wake up?', 'That depends on your determination, but KYA makes every extra snooze dramatically less convenient.'],
];

function Icon({ name }) {
  const props = {
    viewBox: '0 0 32 32',
    fill: 'none',
    stroke: 'currentColor',
    strokeWidth: 2.4,
    strokeLinecap: 'round',
    strokeLinejoin: 'round',
    'aria-hidden': true,
  };

  if (name === 'button') {
    return <svg {...props}><rect x="5" y="8" width="22" height="16" rx="8"/><path d="M11 16h10M18 12l4 4-4 4"/></svg>;
  }
  if (name === 'file') {
    return <svg {...props}><path d="M9 4h10l5 5v19H9z"/><path d="M19 4v6h5M13 16h7M13 21h7"/></svg>;
  }
  if (name === 'scan') {
    return <svg {...props}><path d="M4 11V5h6M22 5h6v6M28 21v6h-6M10 27H4v-6"/><circle cx="16" cy="14" r="4"/><path d="M9 25c1.5-4.5 4-6.5 7-6.5s5.5 2 7 6.5"/></svg>;
  }
  if (name === 'officer') {
    return <img className="officer-mini" src={albyOfficer} alt="" aria-hidden="true" />;
  }
  if (name === 'puzzle') {
    return <svg {...props}><path d="M12 5h5a3 3 0 1 0 6 0h4v7h-4a3 3 0 1 0 0 6h4v9h-9v-4a3 3 0 1 0-6 0v4H5v-9h4a3 3 0 1 0 0-6H5V5h7z"/></svg>;
  }
  if (name === 'folder') {
    return <svg {...props}><path d="M4 9h10l3 3h11v15H4z"/><path d="M4 9V6h9l3 3"/></svg>;
  }
  if (name === 'user') {
    return <svg {...props}><circle cx="16" cy="11" r="5"/><path d="M6 29c1-7 4.5-10 10-10s9 3 10 10"/></svg>;
  }
  return null;
}

function AppLink({ children = 'Try the demo', className = 'button button-primary' }) {
  return (
    <a className={className} href={APP_URL} target="_blank" rel="noopener noreferrer">
      {children}
    </a>
  );
}

function Brand() {
  return (
    <a className="brand" href="#top" aria-label="KYA home">
      <img src={appIcon} alt="" width="48" height="48" />
      <span className="brand-copy">KYA<small>Know Your Alarm</small></span>
    </a>
  );
}

function PhoneFrame({ src, alt, className = '', eager = false }) {
  return (
    <div className={`phone-frame ${className}`.trim()}>
      <div className="phone-screen">
        <img
          src={src}
          alt={alt}
          width="1170"
          height="2532"
          loading={eager ? 'eager' : 'lazy'}
          decoding="async"
        />
      </div>
    </div>
  );
}

function Header() {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <header className="site-header">
      <nav className="nav container" aria-label="Primary navigation">
        <Brand />
        <div className={`nav-links ${menuOpen ? 'open' : ''}`}>
          <a href="#features" onClick={() => setMenuOpen(false)}>Features</a>
          <a href="#how" onClick={() => setMenuOpen(false)}>How it works</a>
          <a href="#why" onClick={() => setMenuOpen(false)}>Why KYA</a>
          <a href="#faq" onClick={() => setMenuOpen(false)}>FAQ</a>
        </div>
        <AppLink className="button button-blue nav-cta" />
        <button
          aria-expanded={menuOpen}
          aria-label={menuOpen ? 'Close navigation menu' : 'Open navigation menu'}
          className="menu-button"
          onClick={() => setMenuOpen((open) => !open)}
          type="button"
        >
          <span />
        </button>
      </nav>
    </header>
  );
}

function Hero() {
  return (
    <section className="hero" aria-labelledby="hero-title">
      <div className="container hero-grid">
        <div className="hero-copy reveal reveal-left">
          <h1 id="hero-title">Snoozing now requires <span className="hero-highlight">paperwork.</span></h1>
          <p className="hero-subtitle">The alarm clock that makes getting up easier than asking for five more minutes.</p>
          <div className="hero-actions">
            <AppLink className="button button-blue" />
            <a className="button button-white" href="#how">See how it works</a>
          </div>
        </div>

        <div className="hero-visual reveal reveal-right" style={{ '--reveal-delay': '120ms' }}>
          <div className="hero-sun" aria-hidden="true" />
          <PhoneFrame src={alarmScreen} alt="KYA alarm screen with Alby and snooze controls" className="hero-phone phone-one" eager />
          <PhoneFrame src={appealScreen} alt="KYA Snooze Officer rejecting an appeal" className="hero-phone phone-two" eager />
          <div className="reject-stamp">Rejected</div>
          <img className="hero-alby" src={albyOfficer} alt="" width="1313" height="1198" />
        </div>
      </div>
    </section>
  );
}


function Features() {
  return (
    <section className="features" id="features" aria-labelledby="features-title">
      <div className="container">
        <div className="section-title reveal">
          <h2 id="features-title">Everything standing between you and 5 more minutes.</h2>
        </div>
        <div className="feature-grid">
          {features.map((feature, index) => (
            <article className="feature reveal reveal-scale" key={feature.title} style={{ '--reveal-delay': `${index * 65}ms` }}>
              <span className={`feature-icon ${feature.iconClass}`}><Icon name={feature.icon} /></span>
              <div>
                <h3>{feature.title}</h3>
                <p>{feature.copy}</p>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

function DueProcess() {
  return (
    <section className="due-process" id="why" aria-labelledby="due-title">
      <div className="container due-card reveal reveal-scale">
        <PhoneFrame src={verificationScreen} alt="KYA quick verification screen" className="due-phone" />
        <div className="sticky-note">SNOOZING<br />IS A PRIVILEGE,<br />NOT A RIGHT.</div>
        <div className="seal"><span>Dept. of Mornings · Official Form</span></div>
        <div className="due-copy">
          <h2 id="due-title">One alarm. Eleven screens of due process.</h2>
          <p>From forms to facial recognition, KYA turns every snooze into a full bureaucratic journey. By the time you’re done, getting up will feel easier.</p>
          <AppLink className="button button-blue" />
        </div>
        <span className="note due-note">Tedious today.<br />A brighter<br />tomorrow.</span>
      </div>
    </section>
  );
}

function HowItWorks() {
  const [activeStep, setActiveStep] = useState(0);
  const stepElements = useRef([]);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        const activeEntry = entries.find((entry) => entry.isIntersecting);
        if (activeEntry) {
          setActiveStep(Number(activeEntry.target.dataset.step));
        }
      },
      { rootMargin: '-42% 0px -42% 0px' },
    );

    stepElements.current.forEach((element) => {
      if (element) observer.observe(element);
    });

    return () => observer.disconnect();
  }, []);

  return (
    <section className="how-section" id="how" aria-labelledby="how-title">
      <div className="container">
        <div className="how-title section-title reveal">
          <h2 id="how-title">Why people actually get out of bed.</h2>
          <p>The full five-step path from first ring to reluctant freedom.</p>
        </div>

        <div className="how-grid">
          <div className="how-visual-column reveal reveal-right" aria-hidden="true">
            <div className="how-visual-sticky">
              <div className="how-screen-stage">
                {steps.map((step, index) => (
                  <div className={`screen-layer ${activeStep === index ? 'active' : ''}`} key={step.number}>
                    <PhoneFrame src={step.screen} alt="" className="how-phone" eager={index === 0} />
                  </div>
                ))}
                <div className="screen-status">
                  <span>{activeStep + 1}</span>
                  {steps[activeStep].label}
                </div>
                <div className="how-dots">
                  {steps.map((step, index) => (
                    <span className={activeStep === index ? 'active' : ''} key={step.number} />
                  ))}
                </div>
              </div>
            </div>
          </div>

          <ol className="step-list">
            {steps.map((step, index) => (
              <li
                aria-current={activeStep === index ? 'step' : undefined}
                className={`step ${activeStep === index ? 'active' : ''}`}
                data-step={index}
                key={step.number}
                ref={(element) => {
                  stepElements.current[index] = element;
                }}
              >
                <div className="mobile-step-phone" aria-hidden="true">
                  <PhoneFrame src={step.screen} alt="" eager={index === 0} />
                </div>
                <span className={`step-number ${step.color}`}>{step.number}</span>
                <div>
                  <h3>{step.title}</h3>
                  <p>{step.copy}</p>
                </div>
              </li>
            ))}
          </ol>
        </div>
      </div>
    </section>
  );
}

function Testimonials() {
  return (
    <section className="testimonials" aria-labelledby="testimonials-title">
      <div className="container">
        <div className="testimonials-head reveal reveal-left">
          <h2 id="testimonials-title">Testimony submitted under oath.</h2>
        </div>
        <div className="testimonial-grid">
          {testimonials.map((testimonial, index) => (
            <article className="testimonial reveal reveal-scale" key={testimonial.caseNumber} style={{ '--reveal-delay': `${index * 90}ms` }}>
              <div className="witness">
                <span className="avatar"><Icon name="user" /></span>
                <div>
                  <div className="case mono">{testimonial.caseNumber}</div>
                  <span className="stars" aria-label="Five out of five stars">★★★★★</span>
                </div>
              </div>
              <blockquote>“{testimonial.quote}”</blockquote>
              <footer>— {testimonial.name}</footer>
              <span className={`mini-stamp ${testimonial.status === 'Approved' ? 'approved-text' : 'pending-text'}`}>{testimonial.status}</span>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

function Faq() {
  const [open, setOpen] = useState(0);

  return (
    <section className="faq" id="faq" aria-labelledby="faq-title">
      <div className="container faq-grid">
        <div className="faq-mascot reveal reveal-left">
          <img src={albyHappy} alt="" loading="lazy" width="1314" height="1197" />
          <div className="speech">Curious?<br />I’ve got answers.<br />(Probably.)</div>
        </div>
        <div className="reveal reveal-right" style={{ '--reveal-delay': '100ms' }}>
          <h2 id="faq-title">Questions, answered.</h2>
          <div className="faq-list">
            {faqs.map(([question, answer], index) => {
              const isOpen = open === index;
              const answerId = `faq-answer-${index}`;
              return (
                <div className={`faq-item ${isOpen ? 'open' : ''}`} key={question}>
                  <button
                    className="faq-question"
                    type="button"
                    aria-expanded={isOpen}
                    aria-controls={answerId}
                    onClick={() => setOpen(isOpen ? -1 : index)}
                  >
                    <span>{question}</span>
                    <span className="faq-plus" aria-hidden="true">+</span>
                  </button>
                  <div className="faq-answer" id={answerId} aria-hidden={!isOpen}><div><p>{answer}</p></div></div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}

function FinalCta() {
  return (
    <section className="final">
      <div className="container final-card reveal reveal-scale">
        <div className="final-copy">
          <h2>File your last snooze request.</h2>
          <p>Compliance is a lifestyle.</p>
          <AppLink className="button button-yellow" />
        </div>
        <PhoneFrame src={successScreen} alt="KYA Verified confirmation screen" className="final-phone" />
        <div className="reject-stamp final-stamp">Approved</div>
        <div className="note final-note">Same tomorrow.<br />Brighter you.</div>
      </div>
    </section>
  );
}

function Footer() {
  return (
    <footer className="site-footer">
      <div className="container">
        <div className="footer-row">
          <div>
            <Brand />
            <div className="footer-tagline">Please sleep efficiently.</div>
          </div>
          <nav className="footer-links" aria-label="Footer navigation">
            <a href="#features">Features</a>
            <a href="#how">How it works</a>
            <a href="#why">Why KYA</a>
            <a href="#faq">FAQ</a>
          </nav>
          <div className="social-links" aria-label="Social channels">
            <span aria-label="X">X</span>
            <span aria-label="Instagram">IG</span>
            <span aria-label="TikTok">TT</span>
            <span aria-label="YouTube">YT</span>
          </div>
        </div>
        <div className="footer-end mono">© 2026 KYA · Form KYA-END · All snoozes final</div>
      </div>
    </footer>
  );
}

function useScrollReveal() {
  useEffect(() => {
    const elements = [...document.querySelectorAll('.reveal')];
    if (!('IntersectionObserver' in window)) {
      elements.forEach((element) => element.classList.add('is-visible'));
      return undefined;
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          entry.target.classList.add('is-visible');
          observer.unobserve(entry.target);
        });
      },
      { rootMargin: '0px 0px -10% 0px', threshold: 0.08 },
    );

    elements.forEach((element) => observer.observe(element));
    return () => observer.disconnect();
  }, []);
}

export default function App() {
  useScrollReveal();

  return (
    <>
      <a className="skip-link" href="#main-content">Skip to content</a>
      <Header />
      <main id="main-content">
        <div id="top" />
        <Hero />
        <HowItWorks />
        <Features />
        <DueProcess />
        <Testimonials />
        <Faq />
        <FinalCta />
      </main>
      <Footer />
    </>
  );
}
