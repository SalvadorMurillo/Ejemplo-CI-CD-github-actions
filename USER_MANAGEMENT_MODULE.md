# User Management Module - Implementation Summary

## Overview

**Director**, and **Subdirector** roles can access this module.

## Key Features Implemented

### 1. **Permission System**

- **Admin**: Has absolute authority over the app

  - Can see ALL users including other admins
  - Can create, edit, and delete ANY user including other admins
  - Can assign ANY role including admin

- **Director & Subdirector**: Have full management permissions EXCEPT:
  - CANNOT see admin users
  - CANNOT create admin users
  - CANNOT edit admin users
  - CANNOT delete admin users
  - CANNOT assign admin role to users

### 2. **User Service** (`lib/services/user_service.dart`)

Complete CRUD operations with security checks:

- `getUsers()` - List users filtered by role permissions
- `getUserById()` - Get single user details
- `createUser()` - Create new user with role validation
- `updateUser()` - Update existing user
- `deleteUser()` - Soft delete (deactivate user)
- `reactivateUser()` - Reactivate deactivated user
- `resetUserPassword()` - Reset user password
- `getUserStatistics()` - Get user statistics

All operations include:

- Role permission validation
- Admin user filtering for non-admin users
- Audit logging

### 3. **Users Provider** (`lib/providers/users_provider.dart`)

State management for users module:

- User list management
- Search and filtering
- Loading states
- Error handling
- Statistics tracking

### 4. **Users Screen** (`lib/screens/users/users_screen.dart`)

Main interface with:

- **Access Control**: Only accessible by Admin, Director, Subdirector
- **Statistics Dashboard**: Total, Active, Inactive users
- **Search & Filter**: By name, email, role, status
- **User List**: Card-based display with role badges and status indicators
- **Actions Menu**: View, Edit, Reset Password, Deactivate/Reactivate

### 5. **Dialog Widgets**

#### User Form Dialog (`widgets/user_form_dialog.dart`)

- Create new users or edit existing users
- Form validation
- Role selection (filtered by permissions)
- Password creation (new users only)
- Active status toggle (edit mode)

#### User Details Dialog (`widgets/user_details_dialog.dart`)

- View complete user information
- Personal information section
- System information section
- Formatted dates
- Current user indicator

#### Password Reset Dialog (`widgets/password_reset_dialog.dart`)

- Reset password for any user
- Password confirmation
- Permission validation
- Warning messages

## Security Features

### 1. **Role-Based Filtering**

```dart
// Admin users are filtered out for non-admin users
if (currentUser.role != UserRole.admin) {
  query = query.neq('role', UserRole.admin.name);
}
```

### 2. **Operation Validation**

Every operation validates:

- User has permission for the operation
- Target user is not admin (unless current user is admin)
- User cannot delete themselves

### 3. **Audit Logging**

All operations are logged with:

- Action type (INSERT, UPDATE, DELETE)
- User performing the action
- Old and new values
- Timestamp

## User Interface Elements

### Statistics Cards

- Total Users
- Active Users
- Inactive Users

### Search & Filters

- Text search (name, email)
- Role filter dropdown
- Status filter (Active/Inactive/All)
- Clear filters button

### User Cards

- Avatar with initial
- Full name and email
- Role badge (color-coded)
- Status badge (Active/Inactive)
- "You" indicator for current user
- Action menu (context-based)

### Color Coding by Role

- Admin: Red
- Director: Purple
- Subdirector: Deep Purple
- Social Worker: Blue
- Prefect: Cyan
- Counselor: Teal
- USAER: Green
- Academic Coordinator: Amber
- Medico: Pink
- Docente: Orange

## Files Created/Modified

### New Files:

1. `lib/services/user_service.dart` - User management service
2. `lib/providers/users_provider.dart` - State management
3. `lib/screens/users/widgets/user_form_dialog.dart` - Create/Edit form
4. `lib/screens/users/widgets/user_details_dialog.dart` - View details
5. `lib/screens/users/widgets/password_reset_dialog.dart` - Password reset

### Modified Files:

1. `lib/screens/users/users_screen.dart` - Complete rewrite
2. `lib/main.dart` - Added UsersProvider

## Usage

### Accessing the Module

- Navigate to "Gestión de Usuarios" from the app drawer
- Only visible to Admin, Director, and Subdirector

### Creating a User

1. Click "Nuevo Usuario" FAB
2. Fill in the form:
   - First Name \*
   - Last Name \*
   - Email \*
   - Phone (optional)
   - Role \* (filtered by permissions)
   - Password \* (for new users)
3. Click "Crear"

### Editing a User

1. Click the menu on a user card
2. Select "Editar"
3. Modify fields
4. Toggle active status if needed
5. Click "Guardar"

### Resetting Password

1. Click the menu on a user card
2. Select "Restablecer contraseña"
3. Enter new password
4. Confirm password
5. Click "Restablecer"

### Deactivating a User

1. Click the menu on a user card
2. Select "Desactivar"
3. Confirm the action

- User cannot login but data is preserved

### Reactivating a User

1. Filter to show inactive users
2. Click the menu on an inactive user
3. Select "Reactivar"
4. Confirm the action

## Database Integration

Uses existing `users` table from Supabase with:

- Role-based row-level security
- Admin user protection
- Audit trail support

## Testing Checklist

- [ ] Admin can see all users including other admins
- [ ] Director cannot see admin users
- [ ] Subdirector cannot see admin users
- [ ] Admin can create admin users
- [ ] Director cannot create admin users
- [ ] Users cannot delete themselves
- [ ] Password reset works correctly
- [ ] Search and filters work
- [ ] Statistics update correctly
- [ ] Audit logs are created
- [ ] Inactive users cannot login

## Future Enhancements

- Bulk user operations
- Export users to CSV
- User activity logs
- Profile image upload
- Email notifications on password reset
- Two-factor authentication
