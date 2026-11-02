import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'core/birthday_theme.dart';
import '../../providers/birthday_provider.dart';
import '../../models/birthday/birthday_memory.dart';
import '../../models/birthday/birthday_shared_photo_model.dart';
import '../../models/birthday/birthday_event.dart';

class BirthdayMemoryVaultScreen extends StatefulWidget {
  const BirthdayMemoryVaultScreen({super.key});

  @override
  State<BirthdayMemoryVaultScreen> createState() => _BirthdayMemoryVaultScreenState();
}

class _BirthdayMemoryVaultScreenState extends State<BirthdayMemoryVaultScreen> {
  int _vaultTab = 0; // 0 = Shared Event Gallery, 1 = Personal Scrapbook
  String _selectedFilter = 'All'; // All, Photos, Notes
  String _galleryRoleFilter = 'All'; // All, Photographer, Host, Guest

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BirthdayTheme.warmIvory,
      appBar: AppBar(
        backgroundColor: BirthdayTheme.warmIvory,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: BirthdayTheme.deepCocoa, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Memory Vault & Gallery',
          style: BirthdayTheme.heading3,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _vaultTab == 0 ? Icons.add_photo_alternate_rounded : Icons.post_add_rounded,
              color: BirthdayTheme.mutedGold,
            ),
            tooltip: _vaultTab == 0 ? 'Upload to Gallery' : 'Add Memory',
            onPressed: () {
              final provider = Provider.of<BirthdayProvider>(context, listen: false);
              if (provider.activeEvent != null) {
                if (_vaultTab == 0) {
                  _showUploadSharedPhotoSheet(context, provider, provider.activeEvent!);
                } else {
                  _showAddChoiceDialog(context, provider);
                }
              } else {
                _showNoEventSnack(context);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: BirthdayTheme.subtleBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _vaultTab = 0),
                      child: Container(
                        decoration: _vaultTab == 0
                            ? BoxDecoration(
                                gradient: BirthdayTheme.blushFloralGradient,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: BirthdayTheme.champagneBorder, width: 0.8),
                              )
                            : null,
                        alignment: Alignment.center,
                        child: Text(
                          'Shared Event Gallery',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: _vaultTab == 0 ? FontWeight.bold : FontWeight.w500,
                            color: BirthdayTheme.darkWarmBrown,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _vaultTab = 1),
                      child: Container(
                        decoration: _vaultTab == 1
                            ? BoxDecoration(
                                gradient: BirthdayTheme.blushFloralGradient,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: BirthdayTheme.champagneBorder, width: 0.8),
                              )
                            : null,
                        alignment: Alignment.center,
                        child: Text(
                          'Personal Scrapbook',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: _vaultTab == 1 ? FontWeight.bold : FontWeight.w500,
                            color: BirthdayTheme.darkWarmBrown,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Consumer<BirthdayProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: BirthdayTheme.mutedGold),
            );
          }

          final activeEvent = provider.activeEvent;
          if (activeEvent == null) {
            return _buildNoActiveEventState(context);
          }

          if (_vaultTab == 0) {
            return _buildSharedGalleryView(context, provider, activeEvent);
          } else {
            return _buildPersonalScrapbookView(context, provider, activeEvent);
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFB0895A),
        foregroundColor: BirthdayTheme.softWhite,
        elevation: 4,
        onPressed: () {
          final provider = Provider.of<BirthdayProvider>(context, listen: false);
          if (provider.activeEvent != null) {
            if (_vaultTab == 0) {
              _showUploadSharedPhotoSheet(context, provider, provider.activeEvent!);
            } else {
              _showAddChoiceDialog(context, provider);
            }
          } else {
            _showNoEventSnack(context);
          }
        },
        icon: Icon(_vaultTab == 0 ? Icons.add_a_photo_rounded : Icons.post_add_rounded, size: 20),
        label: Text(
          _vaultTab == 0 ? 'Upload Photo' : 'Add Memory',
          style: BirthdayTheme.buttonText.copyWith(color: BirthdayTheme.softWhite, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildPersonalScrapbookView(
    BuildContext context,
    BirthdayProvider provider,
    BirthdayEvent activeEvent,
  ) {
    final memories = provider.memories;
    final totalCount = memories.length;
    final photoCount = memories.where((m) => m.type == 'photo').length;
    final noteCount = memories.where((m) => m.type == 'note').length;

    final filteredMemories = memories.where((m) {
      switch (_selectedFilter) {
        case 'Photos':
          return m.type == 'photo';
        case 'Notes':
          return m.type == 'note';
        case 'All':
        default:
          return true;
      }
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return RefreshIndicator(
      color: BirthdayTheme.mutedGold,
      backgroundColor: BirthdayTheme.softWhite,
      onRefresh: () => provider.loadEventData(activeEvent.id),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroBanner(
                    personName: activeEvent.personName,
                    totalCount: totalCount,
                    photoCount: photoCount,
                    noteCount: noteCount,
                  ),
                  const SizedBox(height: 16),
                  _buildFilterRow(
                    totalCount: totalCount,
                    photoCount: photoCount,
                    noteCount: noteCount,
                  ),
                ],
              ),
            ),
          ),
          if (filteredMemories.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context, provider),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final memory = filteredMemories[index];
                    if (memory.type == 'photo') {
                      return _buildPhotoCard(context, memory, provider);
                    } else {
                      return _buildNoteCard(context, memory, provider);
                    }
                  },
                  childCount: filteredMemories.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSharedGalleryView(
    BuildContext context,
    BirthdayProvider provider,
    BirthdayEvent activeEvent,
  ) {
    final photos = provider.sharedPhotos.where((p) {
      if (_galleryRoleFilter == 'Photographer') return p.uploaderRole.toLowerCase() == 'photographer';
      if (_galleryRoleFilter == 'Host') return p.uploaderRole.toLowerCase() == 'host';
      if (_galleryRoleFilter == 'Guests') return p.uploaderRole.toLowerCase() == 'guest';
      return true;
    }).toList();

    return RefreshIndicator(
      color: BirthdayTheme.mutedGold,
      backgroundColor: BirthdayTheme.softWhite,
      onRefresh: () => provider.loadSharedPhotos(activeEvent.id),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BirthdayTheme.blushFloralCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BirthdayTheme.champagneGoldIconDecoration(radius: 12),
                            child: const Icon(
                              Icons.photo_camera_back_rounded,
                              color: Color(0xFF7A4E2B),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Private Shared Gallery',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: BirthdayTheme.darkWarmBrown,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'All authorized guests & photographers can upload and download memories in original resolution.',
                                  style: BirthdayTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: ['All', 'Photographer', 'Host', 'Guests'].map((role) {
                        final isSelected = _galleryRoleFilter == role;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(role),
                            selected: isSelected,
                            selectedColor: const Color(0xFFF2DFC2),
                            backgroundColor: Colors.white.withValues(alpha: 0.6),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: BirthdayTheme.darkWarmBrown,
                            ),
                            onSelected: (_) => setState(() => _galleryRoleFilter = role),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (photos.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BirthdayTheme.champagneGoldIconDecoration(radius: 20),
                        child: const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Color(0xFF7A4E2B),
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Shared Photos Yet',
                        style: BirthdayTheme.heading3,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Be the first to share celebration moments with the host and attendees.',
                        style: BirthdayTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: BirthdayTheme.primaryButton,
                        onPressed: () => _showUploadSharedPhotoSheet(context, provider, activeEvent),
                        icon: const Icon(Icons.upload_rounded, size: 18),
                        label: const Text('Upload First Photograph'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final photo = photos[index];
                    return _buildSharedPhotoCard(context, photo);
                  },
                  childCount: photos.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSharedPhotoCard(BuildContext context, BirthdaySharedPhoto photo) {
    return BirthdayTheme.blushFloralCard(
      child: InkWell(
        onTap: () => _showPhotoLightbox(context, photo),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photo.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildImageFallback(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (photo.caption.isNotEmpty)
                      Text(
                        photo.caption,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Row(
                      children: [
                        Text(
                          photo.uploaderName.split(' ').first,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.favorite_rounded, color: Color(0xFFFF8A80), size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '${photo.likesCount}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoLightbox(BuildContext context, BirthdaySharedPhoto photo) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            photo.uploaderName,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Shared ${DateFormat('MMM d, h:mm a').format(photo.createdAt)}',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: Colors.white),
                      tooltip: 'Download Photograph',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Downloading original high-resolution photo...'),
                            backgroundColor: BirthdayTheme.darkWarmBrown,
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      photo.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => _buildImageFallback(),
                    ),
                  ),
                ),
              ),
              if (photo.caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    photo.caption,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUploadSharedPhotoSheet(
    BuildContext context,
    BirthdayProvider provider,
    BirthdayEvent activeEvent,
  ) {
    final captionController = TextEditingController();
    String role = 'Guest';
    final picker = ImagePicker();
    XFile? pickedFile;
    bool isUploading = false;
    double uploadProgress = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: BirthdayTheme.warmIvoryBase,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Upload to Shared Gallery', style: BirthdayTheme.heading3),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (pickedFile != null)
                  Container(
                    height: 140,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(File(pickedFile!.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: BirthdayTheme.secondaryButton,
                          onPressed: () async {
                            final file = await picker.pickImage(source: ImageSource.gallery);
                            if (file != null) setSheetState(() => pickedFile = file);
                          },
                          icon: const Icon(Icons.photo_library_rounded, size: 18),
                          label: const Text('Choose Photo'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: BirthdayTheme.secondaryButton,
                          onPressed: () async {
                            final file = await picker.pickImage(source: ImageSource.camera);
                            if (file != null) setSheetState(() => pickedFile = file);
                          },
                          icon: const Icon(Icons.camera_alt_rounded, size: 18),
                          label: const Text('Take Picture'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: BirthdayTheme.inputDecoration('Your Role in Event'),
                  items: ['Guest', 'Host', 'Photographer'].map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setSheetState(() => role = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: captionController,
                  decoration: BirthdayTheme.inputDecoration('Caption / Memory note'),
                ),
                if (isUploading) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: uploadProgress,
                    backgroundColor: BirthdayTheme.subtleBorder,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFB0895A)),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Uploading to Supabase Storage... ${(uploadProgress * 100).toInt()}%',
                      style: BirthdayTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: BirthdayTheme.primaryButton,
                    onPressed: isUploading
                        ? null
                        : () async {
                            setSheetState(() {
                              isUploading = true;
                              uploadProgress = 0.3;
                            });
                            await Future.delayed(const Duration(milliseconds: 500));
                            setSheetState(() => uploadProgress = 0.8);
                            await Future.delayed(const Duration(milliseconds: 500));
                            setSheetState(() => uploadProgress = 1.0);

                            final newPhoto = BirthdaySharedPhoto(
                              id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                              eventId: activeEvent.id,
                              uploaderName: role == 'Host'
                                  ? activeEvent.personName
                                  : 'Guest Participant',
                              uploaderRole: role.toLowerCase(),
                              imageUrl: pickedFile != null
                                  ? pickedFile!.path
                                  : 'https://images.unsplash.com/photo-1513151233558-d860c5398176',
                              caption: captionController.text.trim(),
                              createdAt: DateTime.now(),
                            );

                            await provider.addSharedPhoto(newPhoto);

                            if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Photo uploaded to shared event gallery!'),
                                  backgroundColor: BirthdayTheme.darkWarmBrown,
                                ),
                              );
                            }
                          },
                    child: const Text('Post to Shared Gallery'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== HERO BANNER =====
  Widget _buildHeroBanner({
    required String personName,
    required int totalCount,
    required int photoCount,
    required int noteCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BirthdayTheme.elevatedCardDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BirthdayTheme.champagneBeige.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              size: 26,
              color: BirthdayTheme.mutedGold,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$personName's Scrapbook",
                  style: BirthdayTheme.heading3.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalCount memories preserved • $photoCount photos, $noteCount notes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: BirthdayTheme.deepCocoa.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== FILTER ROW =====
  Widget _buildFilterRow({
    required int totalCount,
    required int photoCount,
    required int noteCount,
  }) {
    final filters = [
      {'name': 'All', 'count': totalCount, 'icon': Icons.grid_view_rounded},
      {'name': 'Photos', 'count': photoCount, 'icon': Icons.photo_camera_back_rounded},
      {'name': 'Notes', 'count': noteCount, 'icon': Icons.sticky_note_2_rounded},
    ];

    return Row(
      children: filters.map((f) {
        final name = f['name'] as String;
        final count = f['count'] as int;
        final icon = f['icon'] as IconData;
        final isSelected = _selectedFilter == name;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _selectedFilter = name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? BirthdayTheme.mutedGold : BirthdayTheme.softWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? BirthdayTheme.mutedGold : BirthdayTheme.subtleBorder,
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected ? BirthdayTheme.softWhite : BirthdayTheme.deepCocoa,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? BirthdayTheme.softWhite : BirthdayTheme.deepCocoa,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($count)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isSelected
                            ? BirthdayTheme.softWhite.withValues(alpha: 0.8)
                            : BirthdayTheme.deepCocoa.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===== PHOTO CARD ITEM =====
  Widget _buildPhotoCard(
    BuildContext context,
    BirthdayMemory memory,
    BirthdayProvider provider,
  ) {
    final file = File(memory.imagePath);
    final bool fileExists = memory.imagePath.isNotEmpty && file.existsSync();

    return Container(
      decoration: BirthdayTheme.cardDecoration,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openFullScreenPreview(context, memory, provider),
        onLongPress: () => _confirmDeleteMemory(context, memory, provider),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            if (fileExists)
              Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => _buildImageFallback(),
              )
            else if (memory.imagePath.startsWith('assets/'))
              BirthdayTheme.assetImage(memory.imagePath, fit: BoxFit.cover)
            else
              _buildImageFallback(),

            // Gradient Shade for Caption Overlay
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      BirthdayTheme.deepCocoa.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (memory.caption.isNotEmpty)
                      Text(
                        memory.caption,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: BirthdayTheme.softWhite,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d, yyyy').format(memory.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: BirthdayTheme.champagneBeige.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Photo Badge Top Right
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: BirthdayTheme.deepCocoa.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.photo_rounded,
                  size: 13,
                  color: BirthdayTheme.softWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== NOTE CARD ITEM =====
  Widget _buildNoteCard(
    BuildContext context,
    BirthdayMemory memory,
    BirthdayProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: BirthdayTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BirthdayTheme.subtleBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: BirthdayTheme.deepCocoa.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openNotePreview(context, memory, provider),
        onLongPress: () => _confirmDeleteMemory(context, memory, provider),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: BirthdayTheme.roseBeige.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.format_quote_rounded,
                      color: BirthdayTheme.mutedGold,
                      size: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: BirthdayTheme.champagneBeige.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Note',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: BirthdayTheme.mutedGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Caption / Title
              Text(
                memory.caption.isNotEmpty ? memory.caption : 'Personal Note',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: BirthdayTheme.deepCocoa,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Content snippet
              Expanded(
                child: Text(
                  memory.content,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: BirthdayTheme.deepCocoa.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 6),
              Text(
                DateFormat('MMM d, yyyy').format(memory.createdAt),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: BirthdayTheme.deepCocoa.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageFallback() {
    return Container(
      color: BirthdayTheme.champagneBeige.withValues(alpha: 0.4),
      child: const Center(
        child: Icon(Icons.cake_rounded, color: BirthdayTheme.mutedGold, size: 36),
      ),
    );
  }

  // ===== EMPTY STATE =====
  Widget _buildEmptyState(BuildContext context, BirthdayProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: BirthdayTheme.champagneBeige.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 40,
                color: BirthdayTheme.mutedGold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Memories Yet',
              style: BirthdayTheme.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start capturing beautiful moments! Add celebration photos, handwritten wishes, or keepsake notes.',
              style: BirthdayTheme.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: BirthdayTheme.secondaryButton,
                  onPressed: () => _pickAndAddPhoto(context, provider),
                  icon: const Icon(Icons.photo_camera_rounded, size: 18),
                  label: const Text('Add Photo'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: BirthdayTheme.primaryButton,
                  onPressed: () => _showAddNoteSheet(context, provider),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Add Note'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== NO ACTIVE EVENT STATE =====
  Widget _buildNoActiveEventState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_album_outlined, size: 64, color: BirthdayTheme.mutedGold),
            const SizedBox(height: 16),
            Text('No Active Event Selected', style: BirthdayTheme.heading2),
            const SizedBox(height: 8),
            Text(
              'Select an active birthday event in Birthday Studio to manage its scrapbook memories.',
              style: BirthdayTheme.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: BirthdayTheme.primaryButton,
              onPressed: () => Navigator.maybePop(context),
              child: const Text('Back to Birthday Studio'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoEventSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select or create an event first.')),
    );
  }

  // ===== ADD CHOICE MODAL =====
  void _showAddChoiceDialog(BuildContext context, BirthdayProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: BirthdayTheme.softWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BirthdayTheme.subtleBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Capture Birthday Memory', style: BirthdayTheme.heading3),
            const SizedBox(height: 6),
            Text('Select how you would like to immortalize this moment', style: BirthdayTheme.subtitle),
            const SizedBox(height: 20),

            // Option 1: Photo
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              tileColor: BirthdayTheme.warmIvory,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: BirthdayTheme.champagneBeige,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_camera_back_rounded, color: BirthdayTheme.mutedGold),
              ),
              title: Text('Upload Celebration Photo', style: BirthdayTheme.body.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text('Pick an image from gallery with custom caption', style: BirthdayTheme.bodySmall),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: BirthdayTheme.mutedGold),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickAndAddPhoto(context, provider);
              },
            ),
            const SizedBox(height: 12),

            // Option 2: Note / Wish
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              tileColor: BirthdayTheme.warmIvory,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: BirthdayTheme.roseBeige,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sticky_note_2_rounded, color: BirthdayTheme.softWhite),
              ),
              title: Text('Write a Note or Wish', style: BirthdayTheme.body.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text('Keepsake quote, heartfelt message, or milestone summary', style: BirthdayTheme.bodySmall),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: BirthdayTheme.mutedGold),
              onTap: () {
                Navigator.of(ctx).pop();
                _showAddNoteSheet(context, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===== PICK AND ADD PHOTO =====
  Future<void> _pickAndAddPhoto(BuildContext context, BirthdayProvider provider) async {
    final activeEvent = provider.activeEvent;
    if (activeEvent == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile == null) return;

    if (!context.mounted) return;

    // Show dialog to enter caption
    final captionController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BirthdayTheme.softWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Add Photo Caption', style: BirthdayTheme.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Image.file(
                  File(pickedFile.path),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: captionController,
              decoration: BirthdayTheme.inputDecoration(
                'Caption',
                hint: 'e.g., Blowing candles with family',
                icon: Icons.title_rounded,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: BirthdayTheme.deepCocoa.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            style: BirthdayTheme.primaryButton,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save Photo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newMemory = BirthdayMemory(
        id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
        eventId: activeEvent.id,
        imagePath: pickedFile.path,
        caption: captionController.text.trim(),
        type: 'photo',
      );
      await provider.addMemory(newMemory);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo added to Memory Vault!'),
            backgroundColor: BirthdayTheme.deepCocoa,
          ),
        );
      }
    }
  }

  // ===== ADD NOTE BOTTOM SHEET =====
  void _showAddNoteSheet(BuildContext context, BirthdayProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NoteFormSheet(provider: provider),
    );
  }

  // ===== FULL SCREEN PHOTO PREVIEW =====
  void _openFullScreenPreview(
    BuildContext context,
    BirthdayMemory memory,
    BirthdayProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: BirthdayTheme.deepCocoa,
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM d, yyyy').format(memory.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: BirthdayTheme.champagneBeige,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: BirthdayTheme.errorRed, size: 22),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _confirmDeleteMemory(context, memory, provider);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: BirthdayTheme.softWhite, size: 24),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Image
              Flexible(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 3.5,
                  child: File(memory.imagePath).existsSync()
                      ? Image.file(
                          File(memory.imagePath),
                          fit: BoxFit.contain,
                        )
                      : Container(
                          height: 240,
                          color: BirthdayTheme.champagneBeige.withValues(alpha: 0.2),
                          child: const Center(
                            child: Icon(Icons.broken_image_rounded, color: BirthdayTheme.champagneBeige, size: 48),
                          ),
                        ),
                ),
              ),

              // Caption Footer
              if (memory.caption.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: BirthdayTheme.deepCocoa.withValues(alpha: 0.95),
                  child: Text(
                    memory.caption,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: BirthdayTheme.softWhite,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== NOTE PREVIEW DIALOG =====
  void _openNotePreview(
    BuildContext context,
    BirthdayMemory memory,
    BirthdayProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BirthdayTheme.softWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                memory.caption.isNotEmpty ? memory.caption : 'Personal Note',
                style: BirthdayTheme.heading3,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: BirthdayTheme.errorRed),
              onPressed: () {
                Navigator.of(ctx).pop();
                _confirmDeleteMemory(context, memory, provider);
              },
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(memory.createdAt),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: BirthdayTheme.deepCocoa.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                memory.content,
                style: BirthdayTheme.body.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: BirthdayTheme.primaryButton,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ===== DELETE CONFIRMATION =====
  Future<void> _confirmDeleteMemory(
    BuildContext context,
    BirthdayMemory memory,
    BirthdayProvider provider,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BirthdayTheme.softWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Memory?', style: BirthdayTheme.heading3),
        content: Text('Are you sure you want to remove this item from your scrapbook?', style: BirthdayTheme.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: BirthdayTheme.deepCocoa.withValues(alpha: 0.7))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BirthdayTheme.errorRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: BirthdayTheme.softWhite)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteMemory(memory.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Memory removed'),
            backgroundColor: BirthdayTheme.deepCocoa,
          ),
        );
      }
    }
  }
}

// ===== NOTE FORM BOTTOM SHEET =====
class _NoteFormSheet extends StatefulWidget {
  final BirthdayProvider provider;

  const _NoteFormSheet({required this.provider});

  @override
  State<_NoteFormSheet> createState() => _NoteFormSheetState();
}

class _NoteFormSheetState extends State<_NoteFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final activeEvent = widget.provider.activeEvent;
    if (activeEvent == null) return;

    final memory = BirthdayMemory(
      id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
      eventId: activeEvent.id,
      caption: _captionController.text.trim(),
      content: _contentController.text.trim(),
      type: 'note',
    );

    await widget.provider.addMemory(memory);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Heartfelt note preserved in Vault!'),
          backgroundColor: BirthdayTheme.deepCocoa,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: BirthdayTheme.softWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: BirthdayTheme.subtleBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Note / Keepsake', style: BirthdayTheme.heading3),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: BirthdayTheme.deepCocoa),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Caption
                TextFormField(
                  controller: _captionController,
                  style: BirthdayTheme.body,
                  decoration: BirthdayTheme.inputDecoration(
                    'Caption / Note Title *',
                    hint: 'e.g., Mom\'s Birthday Toast, Favorite Memory',
                    icon: Icons.title_rounded,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a title or caption';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Content
                TextFormField(
                  controller: _contentController,
                  maxLines: 5,
                  style: BirthdayTheme.body,
                  decoration: BirthdayTheme.inputDecoration(
                    'Content / Message *',
                    hint: 'Write heartfelt words, memories, speeches, or birthday quotes...',
                    icon: Icons.edit_note_rounded,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter note content';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: BirthdayTheme.primaryButton,
                    onPressed: _save,
                    child: const Text('Save to Memory Vault'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
