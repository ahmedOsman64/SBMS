import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/shared/services/auth_service.dart';
import '../../../../core/shared/services/wallet_service.dart';
import '../../../../core/shared/exceptions/failures.dart';
import '../../data/booking_repository.dart';
import '../../data/models/trip.dart';
import '../../data/models/booking.dart';

// Struct for the active booking process
class BookingFlowState {
  final Trip? selectedTrip;
  final List<String> selectedSeats;
  final String paymentMethod; // 'wallet', 'evc_plus', 'zaad', 'sahal'
  final String phoneNumber;   // For Mobile Money
  final bool isLoading;
  final Failure? error;
  final Booking? completedBooking;

  BookingFlowState({
    this.selectedTrip,
    this.selectedSeats = const [],
    this.paymentMethod = 'wallet',
    this.phoneNumber = '',
    this.isLoading = false,
    this.error,
    this.completedBooking,
  });

  BookingFlowState copyWith({
    Trip? selectedTrip,
    List<String>? selectedSeats,
    String? paymentMethod,
    String? phoneNumber,
    bool? isLoading,
    Failure? error,
    Booking? completedBooking,
    bool clearError = false,
    bool clearBooking = false,
  }) {
    return BookingFlowState(
      selectedTrip: selectedTrip ?? this.selectedTrip,
      selectedSeats: selectedSeats ?? this.selectedSeats,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      completedBooking: clearBooking ? null : (completedBooking ?? this.completedBooking),
    );
  }
}

final bookingFlowControllerProvider = StateNotifierProvider<BookingFlowController, BookingFlowState>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  final authNotifier = ref.watch(authNotifierProvider);
  final walletService = ref.watch(walletServiceProvider.notifier);
  return BookingFlowController(repository, authNotifier.valueOrNull?.id, walletService);
});

class BookingFlowController extends StateNotifier<BookingFlowState> {
  final BookingRepository _repository;
  final String? _currentUserId;
  final WalletService _walletService;

  BookingFlowController(this._repository, this._currentUserId, this._walletService)
      : super(BookingFlowState());

  void selectTrip(Trip trip) {
    state = BookingFlowState(selectedTrip: trip);
  }

  void toggleSeat(String seatCode) {
    if (state.selectedTrip == null) return;
    
    final seats = List<String>.from(state.selectedSeats);
    if (seats.contains(seatCode)) {
      seats.remove(seatCode);
    } else {
      // Allow booking max 4 seats at once as standard rule
      if (seats.length < 4) {
        seats.add(seatCode);
      }
    }
    state = state.copyWith(selectedSeats: seats);
  }

  void selectPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setPhoneNumber(String phone) {
    state = state.copyWith(phoneNumber: phone);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = BookingFlowState();
  }

  Future<void> confirmBooking() async {
    final trip = state.selectedTrip;
    final userId = _currentUserId;
    
    if (trip == null || userId == null || state.selectedSeats.isEmpty) {
      state = state.copyWith(error: const ValidationFailure('Trip session or seats selection is invalid.'));
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    final totalPrice = trip.price * state.selectedSeats.length;

    try {
      // 1. Process payment first
      if (state.paymentMethod == 'wallet') {
        final success = await _walletService.pay(totalPrice);
        if (!success) {
          throw const ValidationFailure('Insufficient wallet balance. Please top up or choose another payment method.');
        }
      } else {
        // Direct mobile money (EVC Plus, Zaad, Sahal) simulate OTP verification gateway
        await Future.delayed(const Duration(seconds: 2));
      }

      // 2. Save Booking to Database
      final booking = await _repository.createBooking(
        userId: userId,
        tripId: trip.id,
        seats: state.selectedSeats,
        totalPrice: totalPrice,
        paymentMethod: state.paymentMethod,
      );

      state = state.copyWith(completedBooking: booking, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : UnknownFailure(e.toString()),
      );
    }
  }
}
