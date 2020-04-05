import pandas
from os.path import dirname, abspath
from sklearn.cluster import KMeans
root = dirname(dirname(abspath(__file__))) + "/"
df_us = pandas.read_csv(root + 'data/us.csv', index_col = 0)
df_int = pandas.read_csv(root + 'data/international.csv', index_col = 0)
df = pandas.concat([df_us,df_int])
df.drop_duplicates(inplace = True)
df_data = df[['jurisdiction', 'retail_recreation', 'grocery_pharmacy', 'parks', 'transit_stations',
       'workplace', 'residential']]
df_data.dropna(inplace = True)
X = df_data[['retail_recreation', 'grocery_pharmacy', 'parks', 'transit_stations',
       'workplace', 'residential']].values
kmeans = KMeans(n_clusters=5, random_state=42).fit(X)
df_data['cluster'] = kmeans.labels_
df_data.to_csv(root + 'data/final_data.csv')
