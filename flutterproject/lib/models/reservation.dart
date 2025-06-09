class Reservation {
  final String slotCode;
  final String date;
  final String time;
  final int duration;

  Reservation({
    required this.slotCode,
    required this.date,
    required this.time,
    required this.duration,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      slotCode: json['slot_code'],
      date: json['date'],
      time: json['time'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slot_code': slotCode,
      'date': date,
      'time': time,
      'duration': duration,
    };
  }
}
