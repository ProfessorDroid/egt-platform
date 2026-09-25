import { Navigate, Route, Routes } from 'react-router-dom';
import { ProtectedRoute, Shell } from './components/Layout';
import { ToastProvider } from './components/ui';
import { AuthProvider } from './auth/AuthContext';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import { RfqDetail, RfqList } from './pages/Rfqs';
import Products from './pages/Products';
import { SupplierDetail, SupplierList } from './pages/Suppliers';
import { OrderDetail, OrderList } from './pages/Orders';
import { ShipmentDetail, ShipmentList } from './pages/Shipments';
import Documents from './pages/Documents';
import { TicketDetail, TicketList } from './pages/Support';
import Users from './pages/Users';
import AuditLog from './pages/AuditLog';

export default function App() {
  return (
    <ToastProvider>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route element={<ProtectedRoute><Shell /></ProtectedRoute>}>
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/rfqs" element={<RfqList />} />
            <Route path="/rfqs/:id" element={<RfqDetail />} />
            <Route path="/products" element={<Products />} />
            <Route path="/suppliers" element={<SupplierList />} />
            <Route path="/suppliers/:id" element={<SupplierDetail />} />
            <Route path="/orders" element={<OrderList />} />
            <Route path="/orders/:id" element={<OrderDetail />} />
            <Route path="/shipments" element={<ShipmentList />} />
            <Route path="/shipments/:id" element={<ShipmentDetail />} />
            <Route path="/documents" element={<Documents />} />
            <Route path="/support" element={<TicketList />} />
            <Route path="/support/:id" element={<TicketDetail />} />
            <Route path="/users" element={<Users />} />
            <Route path="/audit-logs" element={<AuditLog />} />
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="*" element={<Navigate to="/dashboard" replace />} />
          </Route>
        </Routes>
      </AuthProvider>
    </ToastProvider>
  );
}
