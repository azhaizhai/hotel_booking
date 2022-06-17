require 'time'

# assign rooms
# @param {Json[]} bookings
# @param {Integer} num_of_rooms
# @param {Json[]} rooms
# @return {Integer[][]}
def assign_rooms(bookings, num_of_rooms, rooms = nil)
  results = Array.new(num_of_rooms) { Array.new }
  return results if bookings.empty?
  booking_data = bookings.map { |booking| data_format(booking) }.sort { |a, b| a[:checkin] <=> b[:checkin] }
  if rooms.nil?
    assign_rooms_without_lock(booking_data, num_of_rooms, results)
    results
  else
    assign_rooms_with_lock(booking_data, num_of_rooms, results)
    results.map.with_index { |r, i| { room: i + 1, bookings: r } }
  end
end

# assign rooms
# @param {Json[]} booking_data
# @param {Integer} num_of_rooms
# @param {Integer[][]} results
# @param {Time[]} lastest_checkouts
# @param {Integer} exclude_room
# @return {void}
def assign_rooms_without_lock(booking_data, num_of_rooms, results, lastest_checkouts = nil, exclude_room = nil)
  lastest_checkouts ||= Array.new(num_of_rooms)
  booking_data.each do |booking|
    flag = false
    if results[0].empty?
      results[0] << booking[:id]
      lastest_checkouts[0] = booking[:checkout]
      next
    end

    time_length = -1
    insert_index = -1
    num_of_rooms.times do |index|
      next if exclude_room == index
      if results[index].empty?
        if time_length < 0
          results[index] << booking[:id]
          lastest_checkouts[index] = booking[:checkout]
          flag = true
          break
        else
          break
        end
      end

      temp_time_length = booking[:checkin] - lastest_checkouts[index]
      if temp_time_length == 0
        results[index] << booking[:id]
        lastest_checkouts[index] = booking[:checkout]
        flag = true
        insert_index = -1
        break
      elsif temp_time_length > 0
        if time_length < 0 || time_length > temp_time_length
          time_length = temp_time_length
          insert_index = index
        end
      end
    end

    if insert_index != -1
      results[insert_index] << booking[:id]
      lastest_checkouts[insert_index] = booking[:checkout]
      flag = true
    end

    raise_error unless flag
  end
  nil
end

# assign rooms
# @param {Json[]} bookings
# @param {Integer} num_of_rooms
# @param {Integer[][]} results
# @param {Json[]} rooms
# @return {void}
def assign_rooms_with_lock(booking_data, num_of_rooms, results)
  booking_data = booking_data.group_by { |booking| booking[:locked] }
  lastest_checkouts = Array.new(num_of_rooms)
  if booking_data[true].empty?
    assign_rooms_without_lock(booking_data[false], num_of_rooms, results)
    return
  end

  while !booking_data[false].empty? && !booking_data[true].empty?
    booking = booking_data[false][0]
    lock_booking = booking_data[true][0]
    if booking[:checkin] >= lock_booking[:checkin]
      results[lock_booking[:room_id] - 1] << lock_booking[:id]
      lastest_checkouts[lock_booking[:room_id] - 1] = lock_booking[:checkout]
      booking_data[true].shift
    else
      if booking[:checkout] <= lock_booking[:checkin]
        assign_rooms_without_lock([booking], num_of_rooms, results, lastest_checkouts)
      else
        assign_rooms_without_lock([booking], num_of_rooms, results, lastest_checkouts, lock_booking[:room_id] - 1)
      end
      booking_data[false].shift
    end
  end

  while !booking_data[false].empty?
    assign_rooms_without_lock(booking_data[false], num_of_rooms, results, lastest_checkouts)
    return
  end

  while !booking_data[true].empty?
    booking = booking_data[true].shift
    results[booking[:room_id] - 1] << booking[:id]
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
