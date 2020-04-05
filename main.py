import requests
import pdftotext
url_head = 'https://www.gstatic.com/covid19/mobility/'
url_tail = 'Mobility_Report_en.pdf'
local_path = '/Users/karlkatzen/Documents/code/covid/data/'
def _process_data_string(line):
    return [int(string.strip().split()[0][:-1]) if 'baseline' in string else 'None' for string in line.split('  ') if len(string) != 0]
def _identify_subdivision_line(lines):
    leng = len(lines)
    for i in range(2,leng):
        if 'Retail' in lines[i]:
            return i - 1
    return -1
def _find_data_lines(lines):
    return [_process_data_string(line) for line in lines if ('compared to baseline' in line or 'Not enough data' in line)]
def mobility_report_extract(country_code, subdivision = None, date = '2020-03-29'):
    if subdivision:
        url = url_head + date + '_' + country_code + '_' + subdivision.replace(' ','_') + '_' + url_tail
        top_level_name = subdivision
    else:
        url = url_head + date + '_' + country_code + '_' + url_tail
        top_level_name = country_code
    r = requests.get(url)
    if r.status_code == 200:
        file_path = local_path + top_level_name.replace(' ','_') + '.pdf'
        with open(file_path, 'wb') as f:
            f.write(r.content)
        with open(file_path, 'rb') as f:
            pdf = pdftotext.PDF(f)
        leng = len(pdf)
        first = pdf[0]
        second = pdf[1]
        res = {}
        top_level_data = []
        messages = first.split('Mobility trends')[1:]
        for message in messages:
            top_level_data.append(int(message.split('\n')[1][:-1]))
        messages = second.split('Mobility trends')[1:]
        for message in messages:
            top_level_data.append(int(message.split('\n')[1][:-1]))
        res[top_level_name] = top_level_data
        for i in range(2,leng-1):
            lines=pdf[i].split('\n')
            second_sudivision_line_num = _identify_subdivision_line(lines)
            data_res = _find_data_lines(lines)
            data_res[0].extend(data_res[1])
            res[lines[0].strip()] = data_res[0]
            if second_sudivision_line_num != -1:
                data_res[2].extend(data_res[3])
                res[lines[second_sudivision_line_num].strip()] = data_res[2]
        return res
    else:
        print(f"Doesn't work for {top_level_name} at {date}")
        return None
