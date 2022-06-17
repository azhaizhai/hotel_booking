require_relative "my_fancy_room_allocate_algo"

bookings = [
  {
    "checkin": "2017-10-1",
    "checkout": "2017-10-3",
    "id": 1
  },
  {
    "checkin": "2017-10-1",
    "checkout": "2017-10-4",
    "id": 2
  },
  {
    "checkin": "2017-10-3",
    "checkout": "2017-10-6",
    "id": 3
  },
  {
    "checkin": "2017-10-3",
    "checkout": "2017-10-8",
    "id": 4
  },
  {
    "checkin": "2017-10-4",
    "checkout": "2017-10-8",
    "id": 5
  },
  {
    "checkin": "2017-10-8",
    "checkout": "2017-10-12",
    "id": 6
  },
  {
    "checkin": "2017-10-9",
    "checkout": "2017-10-20",
    "id": 7
  },
  {
    "checkin": "2017-10-15",
    "checkout": "2017-10-20",
    "id": 8
  },
  {
    "checkin": "2017-10-21",
    "checkout": "2017-10-30",
    "id": 9
  }
]

num_of_rooms = 3

result = assign_rooms(bookings, num_of_rooms)

puts "part1:"
puts result.to_s