require 'time'

# assign rooms
# @param {Json[]} bookings
# @param {Integer} num_of_rooms
# @param {Json[]} rooms
# @return {Integer[][]}
def assign_rooms(bookings, num_of_rooms, rooms = nil)
  return Array.new(num_of_rooms) { Array.new } if bookings.empty?
  booking_data = bookings.map { |booking| data_format(booking) }.sort { |a, b| a[:checkin] <=> b[:checkin] }
  if rooms.nil?
    assign_rooms_without_lock(booking_data, num_of_rooms)
  else
    assign_rooms_with_lock(booking_data, num_of_rooms)
  end
end

# assign rooms without locked
# @param {Json[]} booking_data
# @param {Integer} num_of_rooms
# @return {Integer[][]}
def assign_rooms_without_lock(booking_data, num_of_rooms)
  results = Array.new(num_of_rooms).map { |a| {} }
  booking_data.each do |booking|
    add_booking(booking, results)
  end
  results.map { |r| r[:bookings]&.map{ |b| b[:id]} }
end

# assign rooms with locked
# @param {Json[]} bookings
# @param {Integer} num_of_rooms
# @return {Json[]}
def assign_rooms_with_lock(booking_data, num_of_rooms)
  results = Array.new(num_of_rooms).map { |a| {} }
  booking_data = booking_data.group_by { |booking| booking[:locked] }
  booking_data[true] = booking_data[true] || []
  booking_data[false] = booking_data[false] || []

  while !booking_data[false].empty? && !booking_data[true].empty?
    unlock_booking = booking_data[false][0]
    lock_booking = booking_data[true][0]
    if unlock_booking[:checkout] <= lock_booking[:checkin]
      add_booking(unlock_booking, results)
      booking_data[false].shift
    else
      if unlock_booking[:checkin] <= lock_booking[:checkin]
        exclude_rooms = booking_data[true].select { |bd| bd[:checkin] < unlock_booking[:checkout] }.map { |bd| bd[:room_id] }.uniq
        add_booking(unlock_booking, results, exclude_rooms)
        booking_data[false].shift
      else
        room_index = results.index { |r| r[:room_id] == lock_booking[:room_id] }
        if room_index.nil?
          add_booking(lock_booking, results)
        else
          results[room_index][:bookings] << lock_booking
        end
        booking_data[true].shift
      end
    end
  end

  while !booking_data[false].empty?
    add_booking(booking_data[false].shift, results)
  end

  while !booking_data[true].empty?
    lock_booking = booking_data[true].shift
    room_index = results.index { |r| r[:room_id] == lock_booking[:room_id] }
    if room_index.nil?
      add_booking(lock_booking, results)
    else
      results[room_index][:bookings] << lock_booking
    end
    booking_data[true].shift
  end
  
  results.map{ |r| {bookings: r[:bookings]&.map{ |b| b[:id]}, room_id: r[:room_id]} }
end

# assign single room
# @param {Json} booking
# @param {Integer[]} results
# @param {Integer[]} exclude_rooms
# @return {void}
def add_booking(booking, results, exclude_rooms = [])
  time_length = -1
  insert_index = -1
  results.length.times do |i|
    next if exclude_rooms.include?(results[i][:room_id])
    if results[i][:bookings].nil?
      if insert_index == -1
        results[i] = {bookings: [booking] }
        results[i][:room_id] = booking[:room_id] if results[i][:room_id].nil? && !booking[:room_id].nil?
        return
      end
      break
    end
    temp_time_length = booking[:checkin] - results[i][:bookings].last[:checkout]
    if temp_time_length >= 0
      if time_length < 0 || time_length > temp_time_length
        time_length = temp_time_length
        insert_index = i
      end
    end
  end
  if insert_index != -1
    results[insert_index][:bookings] << booking
    results[insert_index][:room_id] = booking[:room_id] if results[insert_index][:room_id].nil? && !booking[:room_id].nil?
  end
  nil
end

# initialize booking data
# @param {Json} booking
# @return {Json}
def data_format(booking)
  raise_error if booking[:checkin].nil? || booking[:checkout].nil?
  json = {
    checkin: Time.parse(booking[:checkin]),
    checkout: Time.parse(booking[:checkout]),
    id: booking[:id],
    locked: booking[:locked] ? true : false,
    room_id: booking[:room_id]
  }
  raise_error if json[:checkin] > json[:checkout]
  json
end

def raise_error
  raise "ArgumentError: please check your input data"
end
