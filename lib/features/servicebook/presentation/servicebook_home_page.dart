import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/enums/user_role.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/secure_storage_service.dart';
import '../data/servicebook_api.dart';
import '../domain/models/servicebook_models.dart';

String _text(BuildContext context, String english, String amharic) =>
    Localizations.localeOf(context).languageCode == 'am' ? amharic : english;

String _roleName(BuildContext context, UserRole role) => switch (role) {
  UserRole.client => _text(context, 'Client', 'ደንበኛ'),
  UserRole.individualProvider => _text(
    context,
    'Individual provider',
    'ግለሰብ አገልግሎት ሰጪ',
  ),
  UserRole.companyStaff => _text(context, 'Company staff', 'የድርጅት ሰራተኛ'),
  UserRole.broker => _text(context, 'Broker', 'ደላላ'),
  UserRole.supportAgent => _text(context, 'Support agent', 'የድጋፍ ሰራተኛ'),
  UserRole.administrator => _text(context, 'Administrator', 'አስተዳዳሪ'),
};

class ServiceBookHomePage extends ConsumerStatefulWidget {
  const ServiceBookHomePage({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<ServiceBookHomePage> createState() =>
      _ServiceBookHomePageState();
}

class _ServiceBookHomePageState extends ConsumerState<ServiceBookHomePage> {
  int _index = 0;

  bool get _isProvider =>
      widget.role == UserRole.individualProvider ||
      widget.role == UserRole.companyStaff;

  List<String> get _labels => _isProvider
      ? [
          _text(context, 'My services', 'አገልግሎቶቼ'),
          _text(context, 'Work feed', 'የስራ ማስታወቂያዎች'),
          _text(context, 'Bookings', 'ቦታ ማስያዣዎች'),
          _text(context, 'Safety', 'ደህንነት'),
        ]
      : widget.role == UserRole.client
      ? [
          _text(context, 'Nearby', 'በአቅራቢያ'),
          _text(context, 'Work feed', 'የስራ ማስታወቂያዎች'),
          _text(context, 'Bookings', 'ቦታ ማስያዣዎች'),
          _text(context, 'Safety', 'ደህንነት'),
        ]
      : [
          _text(context, 'Overview', 'አጠቃላይ'),
          _text(context, 'Work feed', 'የስራ ማስታወቂያዎች'),
          _text(context, 'Bookings', 'ቦታ ማስያዣዎች'),
          _text(context, 'Safety', 'ደህንነት'),
        ];

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_index == 0 && widget.role == UserRole.client) {
      body = const NearbyProvidersPage();
    } else if (_index == 0 && _isProvider) {
      body = const MyServicesPage();
    } else if (_index == 0) {
      body = StaffOverviewPage(role: widget.role);
    } else if (_index == 1) {
      body = WorkFeedPage(canCreatePost: widget.role == UserRole.client);
    } else if (_index == 2) {
      body = BookingsPage(canManage: _isProvider);
    } else {
      body = const SafetyPage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ServiceBook'),
        actions: [
          IconButton(
            tooltip: _text(context, 'Change language', 'ቋንቋ ቀይር'),
            onPressed: () {
              final current = Localizations.localeOf(context).languageCode;
              ref
                  .read(localeProvider.notifier)
                  .setLocale(Locale(current == 'en' ? 'am' : 'en'));
            },
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _roleName(context, widget.role),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          for (var i = 0; i < _labels.length; i++)
            NavigationDestination(
              icon: Icon(switch (i) {
                0 =>
                  widget.role == UserRole.client
                      ? Icons.location_searching
                      : Icons.home_repair_service_outlined,
                1 => Icons.dynamic_feed_outlined,
                2 => Icons.event_note_outlined,
                _ => Icons.shield_outlined,
              }),
              label: _labels[i],
            ),
        ],
      ),
    );
  }
}

class NearbyProvidersPage extends StatefulWidget {
  const NearbyProvidersPage({super.key});

  @override
  State<NearbyProvidersPage> createState() => _NearbyProvidersPageState();
}

class _NearbyProvidersPageState extends State<NearbyProvidersPage> {
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _radius = TextEditingController(text: '10');
  final _category = TextEditingController();
  String _meetingMode = 'in_person';
  bool _loading = false;
  String? _error;
  List<ServiceProvider>? _providers;

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    _radius.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final latitude = double.tryParse(_latitude.text.trim());
    final longitude = double.tryParse(_longitude.text.trim());
    final radius = double.tryParse(_radius.text.trim());
    if (latitude == null ||
        longitude == null ||
        radius == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        radius <= 0) {
      setState(
        () => _error = _text(
          context,
          'Enter valid latitude, longitude and radius.',
          'ትክክለኛ ኬክሮስ፣ ኬንትሮስ እና ራዲየስ ያስገቡ።',
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _providers = null;
    });
    try {
      final result = await ServiceBookApi.nearbyProviders(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radius,
        category: _category.text.trim(),
        meetingMode: _meetingMode,
      );
      if (mounted) setState(() => _providers = result);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        _text(context, 'Find services near you', 'በአቅራቢያዎ አገልግሎቶችን ያግኙ'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(
        _text(
          context,
          'Use your location coordinates to search. Location is only sent when you submit.',
          'ለመፈለግ የቦታ መጋጠሚያዎችን ያስገቡ። ቦታው ሲፈልጉ ብቻ ይላካል።',
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _field(
              _latitude,
              _text(context, 'Latitude', 'ኬክሮስ'),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _field(
              _longitude,
              _text(context, 'Longitude', 'ኬንትሮስ'),
              keyboardType: TextInputType.number,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: _field(
              _radius,
              _text(context, 'Radius (km)', 'ርቀት (ኪ.ሜ)'),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _field(
              _category,
              _text(context, 'Category (optional)', 'ምድብ (አማራጭ)'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _meetingMode,
        decoration: InputDecoration(
          labelText: _text(context, 'Meeting mode', 'የስብሰባ አይነት'),
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem(
            value: 'in_person',
            child: Text(_text(context, 'In person', 'ፊት ለፊት')),
          ),
          DropdownMenuItem(
            value: 'remote',
            child: Text(_text(context, 'Remote', 'በርቀት')),
          ),
          DropdownMenuItem(
            value: 'either',
            child: Text(_text(context, 'Either', 'ሁለቱም')),
          ),
        ],
        onChanged: (value) => setState(() => _meetingMode = value ?? 'either'),
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: _loading ? null : _search,
        icon: const Icon(Icons.search),
        label: Text(_text(context, 'Search nearby', 'በአቅራቢያ ፈልግ')),
      ),
      if (_loading) const _LoadingState(),
      if (_error != null) _ErrorState(message: _error!, onRetry: _search),
      if (_providers != null && _providers!.isEmpty)
        _EmptyState(
          message: _text(
            context,
            'No providers found for this search.',
            'ለዚህ ፍለጋ አገልግሎት ሰጪ አልተገኘም።',
          ),
        ),
      if (_providers != null)
        for (final provider in _providers!) _ProviderCard(provider: provider),
    ],
  );
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider});
  final ServiceProvider provider;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 12),
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.handyman_outlined)),
      title: Text(provider.name),
      subtitle: Text(
        [
          if (provider.category != null) provider.category!,
          if (provider.location != null) provider.location!,
          if (provider.rating != null) '★ ${provider.rating}',
        ].join(' • '),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: provider.id.isEmpty
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProviderDetailsPage(providerId: provider.id),
              ),
            ),
    ),
  );
}

class ProviderDetailsPage extends StatefulWidget {
  const ProviderDetailsPage({super.key, required this.providerId});
  final String providerId;

  @override
  State<ProviderDetailsPage> createState() => _ProviderDetailsPageState();
}

class _ProviderDetailsPageState extends State<ProviderDetailsPage> {
  late Future<ServiceProvider> _provider;

  @override
  void initState() {
    super.initState();
    _provider = ServiceBookApi.provider(widget.providerId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_text(context, 'Provider details', 'የአገልግሎት ሰጪ ዝርዝር')),
    ),
    body: FutureBuilder<ServiceProvider>(
      future: _provider,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString(),
            onRetry: () => setState(
              () => _provider = ServiceBookApi.provider(widget.providerId),
            ),
          );
        }
        final provider = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              provider.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (provider.description != null) ...[
              const SizedBox(height: 8),
              Text(provider.description!),
            ],
            if (provider.availability != null) ...[
              const SizedBox(height: 16),
              Text(
                _text(context, 'Availability', 'ተገኝነት'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(provider.availability.toString()),
            ],
            const SizedBox(height: 16),
            Text(
              _text(context, 'Services', 'አገልግሎቶች'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (provider.services.isEmpty)
              Text(
                _text(context, 'No services listed.', 'ምንም አገልግሎት አልተዘረዘረም።'),
              ),
            for (final service in provider.services)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  (service['name'] ?? service['title'] ?? 'Service').toString(),
                ),
                subtitle: Text((service['description'] ?? '').toString()),
                trailing: Text(
                  service['price'] == null ? '' : service['price'].toString(),
                ),
              ),
            const SizedBox(height: 12),
            if (provider.services.isNotEmpty)
              FilledButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _BookingDialog(
                    provider: provider,
                    services: provider.services,
                  ),
                ),
                icon: const Icon(Icons.event_available),
                label: Text(_text(context, 'Request booking', 'ቦታ ለመያዝ ጠይቅ')),
              )
            else
              Text(
                _text(
                  context,
                  'Booking is unavailable until this provider publishes a service.',
                  'ይህ አገልግሎት ሰጪ አገልግሎት እስኪያቀርብ ድረስ ቦታ መያዝ አይቻልም።',
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _BookingDialog extends StatefulWidget {
  const _BookingDialog({required this.provider, required this.services});
  final ServiceProvider provider;
  final List<Map<String, dynamic>> services;

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  late String _serviceId;
  String _meetingMode = 'in_person';
  late DateTime _scheduledAt;
  final _notes = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scheduledAt = DateTime.now().add(const Duration(days: 1));
    final service = widget.services.first;
    _serviceId =
        (service['id'] ?? service['serviceId'] ?? service['service_id'] ?? '')
            .toString();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_serviceId.isEmpty) {
      setState(
        () => _error = _text(
          context,
          'The service has no ID; booking cannot be submitted.',
          'አገልግሎቱ መለያ የለውም፤ ቦታ ማስያዝ አይቻልም።',
        ),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await ServiceBookApi.createBooking(
        providerId: widget.provider.id,
        serviceId: _serviceId,
        scheduledAt: _scheduledAt,
        meetingMode: _meetingMode,
        notes: _notes.text,
      );
      if (!mounted) return;
      if (response['success'] == false) {
        setState(
          () => _error = (response['message'] ?? 'Booking request failed')
              .toString(),
        );
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(context, 'Booking request sent.', 'የቦታ ማስያዣ ጥያቄ ተልኳል።'),
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_text(context, 'Request booking', 'ቦታ ለመያዝ ጠይቅ')),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _serviceId,
          decoration: InputDecoration(
            labelText: _text(context, 'Service', 'አገልግሎት'),
          ),
          items: [
            for (final service in widget.services)
              DropdownMenuItem(
                value:
                    (service['id'] ??
                            service['serviceId'] ??
                            service['service_id'] ??
                            '')
                        .toString(),
                child: Text(
                  (service['name'] ?? service['title'] ?? 'Service').toString(),
                ),
              ),
          ],
          onChanged: (value) => setState(() => _serviceId = value ?? ''),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _meetingMode,
          decoration: InputDecoration(
            labelText: _text(context, 'Meeting mode', 'የስብሰባ አይነት'),
          ),
          items: [
            DropdownMenuItem(
              value: 'in_person',
              child: Text(_text(context, 'In person', 'ፊት ለፊት')),
            ),
            DropdownMenuItem(
              value: 'remote',
              child: Text(_text(context, 'Remote', 'በርቀት')),
            ),
          ],
          onChanged: (value) =>
              setState(() => _meetingMode = value ?? 'in_person'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _saving
              ? null
              : () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _scheduledAt,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_scheduledAt),
                  );
                  if (time == null || !context.mounted) return;
                  setState(() {
                    _scheduledAt = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                  });
                },
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(
            '${MaterialLocalizations.of(context).formatMediumDate(_scheduledAt)} · '
            '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_scheduledAt))}',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _notes,
          decoration: InputDecoration(
            labelText: _text(context, 'Notes (optional)', 'ማስታወሻ (አማራጭ)'),
            border: const OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: Text(_text(context, 'Cancel', 'ሰርዝ')),
      ),
      FilledButton(
        onPressed: _saving ? null : _submit,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_text(context, 'Send request', 'ጥያቄ ላክ')),
      ),
    ],
  );
}

class WorkFeedPage extends StatefulWidget {
  const WorkFeedPage({super.key, required this.canCreatePost});
  final bool canCreatePost;

  @override
  State<WorkFeedPage> createState() => _WorkFeedPageState();
}

class _WorkFeedPageState extends State<WorkFeedPage> {
  late Future<List<ServiceWorkPost>> _posts;

  @override
  void initState() {
    super.initState();
    _posts = ServiceBookApi.workFeed();
  }

  void _reload() => setState(() => _posts = ServiceBookApi.workFeed());

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ServiceWorkPost>>(
    future: _posts,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingState();
      }
      if (snapshot.hasError) {
        return _ErrorState(
          message: snapshot.error.toString(),
          onRetry: _reload,
        );
      }
      final posts = snapshot.data!;
      return RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.canCreatePost) ...[
              FilledButton.icon(
                onPressed: () =>
                    showDialog<bool>(
                      context: context,
                      builder: (_) => const _WorkPostDialog(),
                    ).then((created) {
                      if (created == true) _reload();
                    }),
                icon: const Icon(Icons.add),
                label: Text(
                  _text(context, 'Post a work request', 'የስራ ጥያቄ አውጣ'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (posts.isEmpty)
              _EmptyState(
                message: _text(
                  context,
                  'No work requests yet.',
                  'ገና የስራ ጥያቄ የለም።',
                ),
              ),
            for (final post in posts)
              Card(
                child: ListTile(
                  title: Text(post.title),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      [
                        post.description,
                        if (post.category != null) post.category!,
                        if (post.meetingMode != null) post.meetingMode!,
                        if (post.location != null) post.location!,
                      ].join('\n'),
                    ),
                  ),
                  isThreeLine: true,
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _WorkPostDialog extends StatefulWidget {
  const _WorkPostDialog();

  @override
  State<_WorkPostDialog> createState() => _WorkPostDialogState();
}

class _WorkPostDialogState extends State<_WorkPostDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _category = TextEditingController();
  bool _consent = false;
  bool _submitting = false;
  String _meetingMode = 'in_person';
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty ||
        _description.text.trim().isEmpty ||
        _category.text.trim().isEmpty ||
        !_consent) {
      setState(
        () => _error = _text(
          context,
          'Complete all required fields and provide consent.',
          'ሁሉንም አስፈላጊ መስኮች ይሙሉ እና ፈቃድ ይስጡ።',
        ),
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final response = await ServiceBookApi.createWorkPost(
        title: _title.text,
        description: _description.text,
        category: _category.text,
        meetingMode: _meetingMode,
        consentToShare: _consent,
      );
      if (!mounted) return;
      if (response['success'] == false) {
        setState(
          () => _error = (response['message'] ?? 'Post failed').toString(),
        );
        return;
      }
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(context, 'Work request posted.', 'የስራ ጥያቄ ተለጥፏል።'),
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(_text(context, 'New work request', 'አዲስ የስራ ጥያቄ')),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(_title, _text(context, 'Title', 'ርዕስ')),
          const SizedBox(height: 10),
          _field(_category, _text(context, 'Category', 'ምድብ')),
          const SizedBox(height: 10),
          _field(
            _description,
            _text(context, 'Describe the work', 'ስራውን ይግለጹ'),
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _meetingMode,
            decoration: InputDecoration(
              labelText: _text(context, 'Meeting mode', 'የስብሰባ አይነት'),
            ),
            items: [
              DropdownMenuItem(
                value: 'in_person',
                child: Text(_text(context, 'In person', 'ፊት ለፊት')),
              ),
              DropdownMenuItem(
                value: 'remote',
                child: Text(_text(context, 'Remote', 'በርቀት')),
              ),
              DropdownMenuItem(
                value: 'either',
                child: Text(_text(context, 'Either', 'ሁለቱም')),
              ),
            ],
            onChanged: (value) =>
                setState(() => _meetingMode = value ?? 'either'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _consent,
            onChanged: (value) => setState(() => _consent = value ?? false),
            title: Text(
              _text(
                context,
                'I consent to sharing this request with service providers.',
                'ይህን ጥያቄ ለአገልግሎት ሰጪዎች ማጋራትን እፈቅዳለሁ።',
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _submitting ? null : () => Navigator.pop(context, false),
        child: Text(_text(context, 'Cancel', 'ሰርዝ')),
      ),
      FilledButton(
        onPressed: _submitting ? null : _submit,
        child: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(_text(context, 'Post', 'አውጣ')),
      ),
    ],
  );
}

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key, required this.canManage});
  final bool canManage;

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  late Future<List<ServiceBooking>> _bookings;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _bookings = ServiceBookApi.bookings();
  }

  void _reload() => setState(() {
    _actionError = null;
    _bookings = ServiceBookApi.bookings();
  });

  Future<void> _setStatus(ServiceBooking booking, String status) async {
    setState(() => _actionError = null);
    try {
      final response = await ServiceBookApi.updateBookingStatus(
        booking.id,
        status,
      );
      if (response['success'] == false) {
        throw Exception(response['message'] ?? 'Booking status update failed');
      }
      _reload();
    } catch (error) {
      if (mounted) setState(() => _actionError = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ServiceBooking>>(
    future: _bookings,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingState();
      }
      if (snapshot.hasError) {
        return _ErrorState(
          message: snapshot.error.toString(),
          onRetry: _reload,
        );
      }
      final bookings = snapshot.data!;
      return RefreshIndicator(
        onRefresh: () async => _reload(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_actionError != null)
              _ErrorState(message: _actionError!, onRetry: _reload),
            if (bookings.isEmpty)
              _EmptyState(
                message: _text(context, 'No bookings yet.', 'ገና ቦታ አልተያዘም።'),
              ),
            for (final booking in bookings)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceName ??
                            _text(
                              context,
                              'Service booking',
                              'የአገልግሎት ቦታ ማስያዣ',
                            ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          '${_text(context, 'Status', 'ሁኔታ')}: ${booking.status}',
                          if (booking.meetingMode != null) booking.meetingMode!,
                          if (booking.scheduledAt != null)
                            MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(booking.scheduledAt!),
                          if (booking.providerName != null)
                            booking.providerName!,
                          if (booking.clientName != null) booking.clientName!,
                        ].join(' • '),
                      ),
                      if (widget.canManage &&
                          const {
                            'pending',
                            'requested',
                          }.contains(booking.status.toLowerCase()))
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton(
                              onPressed: booking.id.isEmpty
                                  ? null
                                  : () => _setStatus(booking, 'confirmed'),
                              child: Text(_text(context, 'Confirm', 'አረጋግጥ')),
                            ),
                            TextButton(
                              onPressed: booking.id.isEmpty
                                  ? null
                                  : () => _setStatus(booking, 'cancelled'),
                              child: Text(_text(context, 'Decline', 'አትቀበል')),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class MyServicesPage extends StatefulWidget {
  const MyServicesPage({super.key});

  @override
  State<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends State<MyServicesPage> {
  late Future<Map<String, dynamic>?> _identity;
  Future<ServiceProvider>? _provider;

  @override
  void initState() {
    super.initState();
    _identity = SecureStorageService.getUserData();
    _loadProvider();
  }

  void _loadProvider() {
    _provider = _identity.then((user) {
      final id = user?['provider_id'] ?? user?['providerId'] ?? user?['id'];
      if (id == null || id.toString().isEmpty) {
        throw StateError('Your account does not include a provider ID.');
      }
      return ServiceBookApi.provider(id.toString());
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ServiceProvider>(
    future: _provider,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const _LoadingState();
      }
      if (snapshot.hasError) {
        return _ErrorState(
          message: snapshot.error.toString(),
          onRetry: () => setState(_loadProvider),
        );
      }
      final provider = snapshot.data!;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(provider.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            _text(context, 'Services', 'አገልግሎቶች'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (provider.services.isEmpty)
            _EmptyState(
              message: _text(
                context,
                'No services published.',
                'ምንም አገልግሎት አልታተመም።',
              ),
            ),
          for (final service in provider.services)
            Card(
              child: ListTile(
                leading: const Icon(Icons.handyman_outlined),
                title: Text(
                  (service['name'] ?? service['title'] ?? 'Service').toString(),
                ),
                subtitle: Text((service['description'] ?? '').toString()),
                trailing: Text((service['price'] ?? '').toString()),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            _text(context, 'Availability', 'ተገኝነት'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            provider.availability?.toString() ??
                _text(
                  context,
                  'Availability has not been published.',
                  'ተገኝነት አልታተመም።',
                ),
          ),
          if (provider.meetingModes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              _text(context, 'Meeting modes', 'የስብሰባ አይነቶች'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(provider.meetingModes.join(', ')),
          ],
          const SizedBox(height: 16),
          Text(
            _text(
              context,
              'Service and availability editing is not enabled in the mobile API contract yet.',
              'የአገልግሎት እና ተገኝነት ማስተካከያ በሞባይል API ውል ገና አልተካተተም።',
            ),
          ),
        ],
      );
    },
  );
}

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Card(
        child: ListTile(
          leading: const Icon(Icons.report_gmailerrorred_outlined),
          title: Text(_text(context, 'Report an issue', 'ችግር ሪፖርት አድርግ')),
          subtitle: Text(
            _text(
              context,
              'Send a concern to the SBMS team.',
              'ስጋትዎን ለSBMS ቡድን ይላኩ።',
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const IssueReportPage())),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.shield_outlined),
          title: Text(_text(context, 'Safety and privacy', 'ደህንነት እና ግላዊነት')),
          subtitle: Text(
            _text(
              context,
              'Share only the information needed for a service request. Use the issue form to report unsafe or inappropriate conduct.',
              'ለአገልግሎት ጥያቄ የሚያስፈልገውን መረጃ ብቻ ያጋሩ። ደህንነት የሌለውን ወይም ተገቢ ያልሆነ ባህሪ ለማሳወቅ የችግር ቅጹን ይጠቀሙ።',
            ),
          ),
        ),
      ),
    ],
  );
}

class IssueReportPage extends StatefulWidget {
  const IssueReportPage({super.key});

  @override
  State<IssueReportPage> createState() => _IssueReportPageState();
}

class _IssueReportPageState extends State<IssueReportPage> {
  final _description = TextEditingController();
  String _category = 'safety';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_description.text.trim().isEmpty) {
      setState(
        () => _error = _text(context, 'Describe the issue.', 'ችግሩን ይግለጹ።'),
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final response = await ServiceBookApi.createIssue(
        category: _category,
        description: _description.text,
      );
      if (!mounted) return;
      if (response['success'] == false) {
        setState(
          () => _error = (response['message'] ?? 'Report failed').toString(),
        );
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(context, 'Issue report submitted.', 'የችግር ሪፖርቱ ተልኳል።'),
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_text(context, 'Report an issue', 'ችግር ሪፖርት አድርግ')),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _text(
            context,
            'For immediate danger, contact local emergency services first.',
            'አስቸኳይ አደጋ ካለ መጀመሪያ የአካባቢዎን የአደጋ ጊዜ አገልግሎት ያነጋግሩ።',
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: InputDecoration(
            labelText: _text(context, 'Issue type', 'የችግር አይነት'),
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: 'safety',
              child: Text(_text(context, 'Safety concern', 'የደህንነት ስጋት')),
            ),
            DropdownMenuItem(
              value: 'service',
              child: Text(_text(context, 'Service issue', 'የአገልግሎት ችግር')),
            ),
            DropdownMenuItem(
              value: 'conduct',
              child: Text(
                _text(context, 'Inappropriate conduct', 'ተገቢ ያልሆነ ባህሪ'),
              ),
            ),
            DropdownMenuItem(
              value: 'other',
              child: Text(_text(context, 'Other', 'ሌላ')),
            ),
          ],
          onChanged: (value) => setState(() => _category = value ?? 'other'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: _text(context, 'Describe what happened', 'የተፈጠረውን ይግለጹ'),
            border: const OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_text(context, 'Submit report', 'ሪፖርት ላክ')),
        ),
      ],
    ),
  );
}

class StaffOverviewPage extends StatelessWidget {
  const StaffOverviewPage({super.key, required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        _text(context, 'ServiceBook workspace', 'የServiceBook የስራ ቦታ'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(
        _text(
          context,
          '${_roleName(context, role)} access is ready. Use the work feed and bookings tabs to review shared work and booking activity.',
          'የ${_roleName(context, role)} መዳረሻ ዝግጁ ነው። የተጋሩ ስራዎችን እና ቦታ ማስያዣዎችን ለመመልከት የስራ ማስታወቂያዎችን እና ቦታ ማስያዣዎችን ይጠቀሙ።',
        ),
      ),
      const SizedBox(height: 12),
      Text(
        _text(
          context,
          'Role-specific administration and support queues are not included in the mobile API contract yet.',
          'ለዚህ ሚና የተለየ የአስተዳደር እና የድጋፍ ስራ ዝርዝር በሞባይል API ውል ገና አልተካተተም።',
        ),
      ),
    ],
  );
}

Widget _field(
  TextEditingController controller,
  String label, {
  TextInputType? keyboardType,
  int maxLines = 1,
}) => TextField(
  controller: controller,
  keyboardType: keyboardType,
  maxLines: maxLines,
  decoration: InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
  ),
);

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(_text(context, 'Retry', 'እንደገና ሞክር')),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(child: Text(message, textAlign: TextAlign.center)),
  );
}
