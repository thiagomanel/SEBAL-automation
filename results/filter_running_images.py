#!/bin/python
import sys
import re
import os
import pdb
import datetime

def get_time_in_seconds(string):
    multiplier = {'s': 1, 'm': 60, 'h': 60 * 60, 'd': 60 * 60 * 24}
    unit = string[-1]
    value = int(string[:-1])
    return value * multiplier[unit]

def check_arguments(arguments):
    pattern = re.compile('\d+[smhd]$')
    if not (len(arguments) == 3 and pattern.match(arguments[2]) and os.path.isfile(arguments[1])):
        sys.stderr.write("Usage: filter_running_images WINDOW")
        sys.stderr.write("\n")
        sys.stderr.write("\n")
        sys.stderr.write("The WINDOW argument is an integer followed by a time unit (s, m, h, d)")
        sys.stderr.write("\n")
        sys.stderr.write("Examples: 30m, 1d, 60s")
        sys.stderr.write("\n")

        exit(1)
    else:
        pass

def get_window_amount_in_seconds(arguments):
    if len(arguments) == 2:
        pattern = re.compile('\d+[smhd]$')
        if pattern.match(arguments[1]):
            return get_time_in_seconds(arguments[1])

    sys.stderr.write("Usage: filter_running_images WINDOW")
    sys.stderr.write("\n")
    sys.stderr.write("\n")
    sys.stderr.write("The WINDOW argument is an integer followed by a time unit (s, m, h, d)")
    sys.stderr.write("\n")
    sys.stderr.write("Examples: 30m, 1d, 60s")
    sys.stderr.write("\n")

    exit(1)

def process_input(lines):
    samples = []
    for line in lines:
        #LT52160661996017CUB00,2017-06-05 10:58:33.478933,1496660313.47893,queued,experimento.manager.naf.lsd.ufcg.edu.br
        #print "LINE:", line
        if line.strip():
            image_name, date_part, utime, state, federation_member = map(str.strip, line.split(","))
            #timestamp = long(datetime.datetime.strptime(date_part, "%Y-%m-%d %H:%M:%S.%f").strftime('%s'))
            timestamp = long(utime.split(".")[0])
            samples.append((image_name, state, timestamp, federation_member))

    samples.sort(key=lambda stamp: stamp[2])

    return samples

def main():
    window = get_window_amount_in_seconds(sys.argv)

    samples = process_input()
    starting_timestamp = samples[0][2]
    ending_timestamp = samples[-1][2]

    if samples:
        print "site usage timestamp type"
        running_images = dict()
        current_window_end = starting_timestamp + window
        for (image_name, state, timestamp, member) in samples:
            if (timestamp > current_window_end):
                for fed_member in running_images:
                    # print str(current_window_end - window) + ',' + \
                    #       str(current_window_end) + ',' + \
                    #       fed_member + ',' + \
                    #       str(running_images[fed_member][1])
                    print fed_member, running_images[fed_member][1]/20.*100, current_window_end, 'running'

                    running_images[fed_member][1] = len(running_images[fed_member][0])

                current_window_end += window

            if member not in running_images:
                # set_of_running_images, maximum_running_images
                running_images[member] = [set(), 0]

            if state == 'running':
                running_images[member][0].add(image_name)
            elif state == 'finished':
                running_images[member][0].remove(image_name)

            running_images[member][1] = max(running_images[member][1], len(running_images[member][0]))

def get_amount_of_windows(start, end, window):
    return ((end - start) / window) + 1

def get_window_index(start, window, timestamp):
    return (timestamp - start) / window

def split(samples, window):
    start = samples[0][2]
    end = samples[-1][2]

    result = {}
    running_images = {}
    for (image_name, state, timestamp, member) in samples:
        if member not in result:
            result[member] = [0] * get_amount_of_windows(start, end, window)
        if member not in running_images:
            running_images[member] = set()

        if state == 'running':
            running_images[member].add(image_name)
        elif state == 'finished':
            running_images[member].remove(image_name)

        index = get_window_index(start, window, timestamp)
        result[member][index] = max(result[member][index], len(running_images[member]))

    pdb.set_trace()

def get_max_running_images_for_window(samples_in_window, current_running_windows, member):
    max_running_in_window = len(current_running_windows[member])
    for (image_name, state, timestamp, fed_member) in samples_in_window:
        if (fed_member == member):
            if state == 'running':
                if (image_name == "LT52170661998333CUB00"):
                    sys.stderr.write("DAMN IMAGE: " + image_name + " " + str(timestamp))
                current_running_windows[fed_member].add(image_name)
            elif state == 'finished':
                current_running_windows[fed_member].remove(image_name)

            max_running_in_window = max(len(current_running_windows[fed_member]), max_running_in_window)

    return max_running_in_window

def split(samples, window):
    start = samples[0][2]
    end = samples[-1][2]

    amount_of_windows = get_amount_of_windows(start, end, window)

    result = {}
    running_images = {}
    for (image_name, state, timestamp, member) in samples:
        if member not in result:
            result[member] = [0] * amount_of_windows
        if member not in running_images:
            running_images[member] = set()

    grouped_samples = [[]] * amount_of_windows
    for sample in samples:
        (image_name, state, timestamp, member) = sample
        grouped_samples[get_window_index(start, window, timestamp)].append(sample)

    print 'site usage timestamp type'
    for i in range(len(grouped_samples)):
        grouped_sample = grouped_samples[i]
        for member in ["experimento.manager.naf.lsd.ufcg.edu.br", "manager.naf.ufscar.br"]:
            m = get_max_running_images_for_window(grouped_sample, running_images, member)
            print member, m, start + window * i, 'running'

def get_max_running_images_for_window(samples_in_window, running_images):
    max_running_in_window = len(running_images)
    for sample in samples_in_window:
        (image_name, state, timestamp, fed_member) = sample
        if state == 'running':
            if (image_name == "LT52170661998333CUB00"):
                sys.stderr.write("DAMN IMAGE: " + str(sample) + " " + str(timestamp) + "\n")
            running_images.add(image_name)
        elif state == 'finished':
            running_images.remove(image_name)

        if (image_name == "LT52170661998333CUB00"):
            sys.stderr.write("MAX DAMN IMAGE: " + str(max_running_in_window) + str(sample) + " " + "\n")

        max_running_in_window = max(len(running_images), max_running_in_window)

    return max_running_in_window

def main():
    check_arguments(sys.argv)

    file = sys.argv[1]
    window = get_time_in_seconds(sys.argv[2])

    f = open(file)
    lines = f.read().split('\n')
    f.close()

    all_samples = process_input(lines)

    samples = dict()
    for sample in all_samples:
        (image_name, state, timestamp, member) = sample
        if member not in samples:
            samples[member] = [sample]
        else:
            samples[member].append(sample)

    running_images = dict()
    for member in samples:
        running_images[member] = set()

    print "site usage timestamp type"
    for member in samples:
        start = samples[member][0][2]
        end = samples[member][-1][2]

        sys.stderr.write("MEMBER: " + member + "\n")
        sys.stderr.write("START: " + str(start) + "\n")
        sys.stderr.write("END: " + str(end) + "\n")

        window_samples = []
        for i in range(get_amount_of_windows(start, end, window)):
            window_samples.append([])

        sys.stderr.write("nwindows: " + str(len(window_samples)) + "\n")

        for i in range(len(samples[member])):
            (image_name, state, timestamp, member) = samples[member][i]
            index = get_window_index(start, window, timestamp)
            window_samples[index].append(samples[member][i])

        for i in range(len(window_samples)):
            window_sample = window_samples[i]
            m = get_max_running_images_for_window(window_sample, running_images[member])
            sys.stderr.write(member + " " + str(100*m/20.) + " " +  str(start) + "  " + str(window * i) + ' running\n')
            print member, 100*m/20., start + window * i, 'running'

main()
# site usage timestamp
