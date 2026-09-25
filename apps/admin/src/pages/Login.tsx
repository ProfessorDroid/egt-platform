/** Sign-in: email + password. The API has no MFA step. */
import React, { useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { Field, useToast } from '../components/ui';

export default function Login() {
  const { login } = useAuth();
  const { push } = useToast();
  const navigate = useNavigate();
  const location = useLocation();
  const from = (location.state as { from?: string } | null)?.from ?? '/dashboard';

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    try {
      await login(email.trim(), password);
      navigate(from, { replace: true });
    } catch (err) {
      push(err instanceof Error ? err.message : 'Sign-in failed.', 'error');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="egt-auth">
      <div className="egt-auth__card">
        <div className="egt-auth__logo">
          <img src="/brand/egt-logo.png" alt="Eagle Goods Trading Co." />
          <p>Admin Console — internal staff only</p>
        </div>
        <form onSubmit={submit}>
          <Field label="Work email">
            <input className="egt-input" type="email" value={email} autoComplete="username"
              onChange={(e) => setEmail(e.target.value)} required autoFocus />
          </Field>
          <Field label="Password">
            <input className="egt-input" type="password" value={password} autoComplete="current-password"
              onChange={(e) => setPassword(e.target.value)} required />
          </Field>
          <button className="egt-btn egt-btn--primary" style={{ width: '100%' }} disabled={busy}>
            {busy ? 'Signing in…' : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  );
}
