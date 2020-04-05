import requests
import pdftotext
url_head = 'https://www.gstatic.com/covid19/mobility/'
url_tail = 'Mobility_Report_en.pdf'
local_path = '/Users/karlkatzen/Documents/code/covid/data/'
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
            subdivision_data = [int(string.strip().split()[0][:-1]) if 'baseline' in string else 'None' for string in lines[2].split('  ') if len(string) != 0]
            subdivision_data.extend([int(string.strip().split()[0][:-1]) if 'baseline' in string else 'None' for string in lines[10].split('  ') if len(string) != 0])
            res[lines[0].strip()] = subdivision_data
            if len(lines) > 27:#Second subdivision
                subdivision_data = [int(string.strip().split()[0][:-1]) if 'baseline' in string else 'None' for string in lines[19].split('  ') if len(string) != 0]
                subdivision_data.extend([int(string.strip().split()[0][:-1]) if 'baseline' in string else 'None' for string in lines[27].split('  ') if len(string) != 0])
                res[lines[17].strip()] = subdivision_data
        return res
    else:
        print(f"Doesn't work for {top_level_name} at {date}")
        return None
