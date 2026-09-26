/**
 * Auth provider: login, session refresh, idle timeout.
 *
 * RECONCILED 2026-09-25: the real API (openapi.yaml v1) has no MFA and no
 * password re-auth endpoint, so the TOTP flow, idle lock screen and
 * re-auth gating were removed. On idle timeout the session is signed out.
 */
import React, { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { api, clearSession, mapError, setTokens } from '../api/client';
import type { LoginResponse, User } from '../api/types';

export const IDLE_TIMEOUT_MS = 15 * 60 * 1000;

interface AuthContextValue {
  user: User | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}

function applyLoginResponse(res: LoginResponse, setUser: (u: User) => void): void {
  if (res.tokens) setTokens(res.tokens);
  setUser(res.user);
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading] = useState(false);
  const idleTimer = useRef<number | null>(null);
  const userRef = useRef<User | null>(null);
  userRef.current = user;

  const logout = useCallback(() => {
    void api.auth.logout();
    clearSession();
    setUser(null);
  }, []);

  /* Session expiry from the HTTP layer forces a full logout. */
  useEffect(() => {
    const handler = () => logout();
    window.addEventListener('egt:session-expired', handler);
    return () => window.removeEventListener('egt:session-expired', handler);
  }, [logout]);

  /* 15-minute idle → sign out (the API offers no re-auth/unlock endpoint). */
  const armIdleTimer = useCallback(() => {
    if (idleTimer.current) window.clearTimeout(idleTimer.current);
    idleTimer.current = window.setTimeout(() => {
      if (userRef.current) logout();
    }, IDLE_TIMEOUT_MS);
  }, [logout]);

  useEffect(() => {
    if (!user) return;
    armIdleTimer();
    const events = ['mousemove', 'keydown', 'click', 'scroll', 'touchstart'] as const;
    const onActivity = () => {
      if (!userRef.current) return;
      armIdleTimer();
    };
    events.forEach((e) => window.addEventListener(e, onActivity, { passive: true }));
    return () => {
      events.forEach((e) => window.removeEventListener(e, onActivity));
      if (idleTimer.current) window.clearTimeout(idleTimer.current);
    };
  }, [user, armIdleTimer]);

  const login = useCallback(async (email: string, password: string): Promise<void> => {
    let res: LoginResponse;
    try {
      res = await api.auth.login(email, password);
    } catch (err) {
      const mapped = mapError(err);
      // On the sign-in screen a 401 means invalid credentials, not an expired session.
      throw new Error(mapped.status === 401 ? 'Email or password is incorrect.' : mapped.message);
    }
    applyLoginResponse(res, setUser);
    armIdleTimer();
  }, [armIdleTimer]);

  const value: AuthContextValue = { user, loading, login, logout };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
