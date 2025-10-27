import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Add this import
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../services/file_service.dart';

class ProfileImageWidget extends StatefulWidget {
  final String? imageUrl;
  final String? imagePath;
  final double size;
  final bool isEditable;
  final VoidCallback? onImageChanged;
  final Function(XFile?)? onImageSelected; // Changed from File? to XFile?
  final String? studentId; // Add this to handle automatic upload

  const ProfileImageWidget({
    super.key,
    this.imageUrl,
    this.imagePath,
    this.size = 120,
    this.isEditable = false,
    this.onImageChanged,
    this.onImageSelected,
    this.studentId, // Add this parameter
  });

  @override
  State<ProfileImageWidget> createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends State<ProfileImageWidget> {
  final FileService _fileService = FileService();
  File? _selectedImage;
  XFile? _selectedXFile;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(child: _buildImageContent()),
        ),
        if (widget.isEditable)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _isLoading ? null : _showImageSourceDialog,
                icon: Icon(
                  _selectedImage != null ||
                          _selectedXFile != null ||
                          widget.imageUrl != null ||
                          widget.imagePath != null
                      ? Icons.edit
                      : Icons.add_a_photo,
                  color: Colors.white,
                  size: 20,
                ),
                iconSize: 32,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.5),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageContent() {
    // Handle web platform
    if (kIsWeb) {
      if (_selectedXFile != null) {
        return Image.network(
          _selectedXFile!.path,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
    } else {
      // Handle mobile platforms
      if (_selectedImage != null) {
        return Image.file(
          _selectedImage!,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
        );
      }

      if (widget.imagePath != null) {
        final file = File(widget.imagePath!);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: widget.size,
            height: widget.size,
          );
        }
      }
    }

    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      // Fix localhost URLs for physical devices
      String correctedUrl = _fixLocalhostUrl(widget.imageUrl!);
      debugPrint('Loading image from URL: $correctedUrl');

      return CachedNetworkImage(
        imageUrl: correctedUrl,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) {
          debugPrint('Error loading image from URL: $url');
          debugPrint('Error details: $error');
          return _buildPlaceholder();
        },
      );
    }

    return _buildPlaceholder();
  }

  /// Fix localhost URLs to use the correct network IP for physical devices
  String _fixLocalhostUrl(String url) {
    if (!kIsWeb && (url.contains('localhost') || url.contains('127.0.0.1'))) {
      // Replace localhost with the local network IP
      // You can get this from your .env file or hardcode it
      const localNetworkIp = '192.168.100.11'; // Match your SUPABASE_URL_Phone
      return url
          .replaceAll('http://localhost:8000', 'http://$localNetworkIp:8000')
          .replaceAll('http://127.0.0.1:8000', 'http://$localNetworkIp:8000')
          .replaceAll('localhost', localNetworkIp)
          .replaceAll('127.0.0.1', localNetworkIp);
    }
    return url;
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.person,
        size: widget.size * 0.5,
        color: Colors.grey[400],
      ),
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              if (!kIsWeb) // Camera is not available on web
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Tomar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null ||
                  _selectedXFile != null ||
                  widget.imageUrl != null ||
                  widget.imagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Eliminar foto',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedXFile = pickedFile;
          if (!kIsWeb) {
            _selectedImage = File(pickedFile.path);
          }
        });

        // Pass the XFile to the parent widget
        widget.onImageSelected?.call(pickedFile);
        widget.onImageChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedXFile = null;
    });
    widget.onImageSelected?.call(null);
    widget.onImageChanged?.call();
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final bool isExpanded;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.isExpanded = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        initiallyExpanded: isExpanded,
        onExpansionChanged: (expanded) => onTap?.call(),
        children: [Padding(padding: const EdgeInsets.all(16), child: child)],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? customValue;
  final bool isImportant;

  const InfoRow({
    super.key,
    required this.label,
    this.value,
    this.customValue,
    this.isImportant = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isImportant ? FontWeight.bold : FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child:
                customValue ??
                Text(
                  value ?? 'No especificado',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isImportant ? FontWeight.bold : null,
                    color: value == null ? Colors.grey[500] : null,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final bool isOutlined;

  const ActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.color,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).primaryColor;

    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveColor,
          side: BorderSide(color: effectiveColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
