#!/usr/bin/env python
# coding: utf-8

# In[27]:


# Загрузка данных
import pandas as pd
import numpy as np
import seaborn as sns
import os

pwd = os.getcwd()
df = pd.read_excel(pwd + '\\Задачи для кандидатов.xlsx', sheet_name = 'Data')
df.head()


# In[28]:


df['target'].value_counts()
# Несбалансированные данные, в целевой переменной 0 сильно преобладают над 1


# In[29]:


df.describe()


# In[30]:


df.dtypes
# Все данные кроме целевой переменной и индексов числовые, отсутствуют категориальные строки


# In[31]:


# Определяем долю отсутствующих значений в предикторах
for col in df.columns:
    pct_missing = np.mean(df[col].isnull())
    print('{} - {}%'.format(col, round(pct_missing*100)))


# In[32]:


# Отбрасываем из датафрейма индексы и указанные столбцы, т.к. в них присутствует очень много пустых значений
df = df.drop(['index', 'x_5', 'x_10', 'x_11'], axis = 1)


# In[33]:


# Выбираем признаки с отсутствующими значениями для замены их средними
cols_to_mean = []
for col in df.columns:
    if df[col].isnull().sum() > 0:
        cols_to_mean.append(col)
        
cols_to_mean


# In[45]:


# Выполняем замену средними и проверяем доли отсутствующих значений
for col in cols_to_mean:
    df[col] = df[col].replace(np.NaN, df[col].mean())
    
df.isna().any()


# In[42]:


import matplotlib.pyplot as plt

correlation_matrix = df.corr(method = 'pearson')
sns.heatmap(correlation_matrix, annot = True, cmap = 'viridis')

plt.title('Correlation Matrix')

plt.gcf().set_size_inches(18, 8)

plt.show()
# Максимальное значение корреляции между двумя зависимыми переменными 0,67. Оставляем все переменные, т.к. между ними отсутствует очень высокая корреляция (хотя бы больше 0.8)


# In[48]:


# Визуализация некоторых данных (больше всего коррелирующих с целевой переменной)
sns.set(style = 'ticks', color_codes = True)
sns.pairplot(data = df, hue = 'target', 
             vars = ['x_1', 'x_2', 'x_3', 'x_13', 'x_19'])


# In[49]:


# Разделяем целевую переменную от предикторов
X, y = df.drop(['target'], axis=1), df['target']


# In[110]:


# Разделяем на обучающую и тестируемую выборки
from sklearn.model_selection import train_test_split

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size = 0.3, random_state = 42)


# In[111]:


# Стандартизация данных
from sklearn import preprocessing
scaler = preprocessing.StandardScaler().fit(X_train)

X_train_scaled = scaler.transform(X_train)
X_test_scaled = scaler.transform(X_test)


# In[112]:


# Определяем важные предикторы методом Recursive Feature Elimination
from sklearn.feature_selection import RFE
from sklearn.linear_model import LogisticRegression

log_model = LogisticRegression()
rfe = RFE(log_model, n_features_to_select = None)
rfe = rfe.fit(X_train_scaled, y_train)

print(rfe.support_)
print(rfe.ranking_)
print(X_train.columns[rfe.support_])
X_train = X_train[X_train.columns[rfe.support_]]

scaler = preprocessing.StandardScaler().fit(X_train)
X_train_scaled = scaler.transform(X_train)


# In[113]:


# Определяем лучшие признаки с помощью p-value
import statsmodels.api as sm

log_model = sm.Logit(y_train, X_train_scaled)
result = log_model.fit()
print(result.summary2())


# In[115]:


# Оставляем переменные с p-value < 0.05
X_train = X_train[['x_1', 'x_3', 'x_13']]
X_test = X_test[['x_1', 'x_3', 'x_13']]

scaler = preprocessing.StandardScaler().fit(X_train)
X_train_scaled = scaler.transform(X_train)
X_test_scaled =  scaler.transform(X_test)


# In[166]:


# Строим модель - логистическая регрессия (выбрал одну из простых, если покажет плохие результаты, необходимо применять более сложные алгоритмы)
from sklearn.linear_model import LogisticRegression
log_model = LogisticRegression()

log_model.fit(X_train_scaled, y_train)
print("score",log_model.score(X_test_scaled, y_test))

y_pred = log_model.predict(X_test_scaled)
y_pred_proba = log_model.predict_proba(X_test_scaled)


# In[138]:


from sklearn.metrics import roc_auc_score
from sklearn.metrics import roc_curve

auc = roc_auc_score(y_test, log_model.predict(X_test_scaled))
fpr, tpr, thresholds = roc_curve(y_test, log_model.predict_proba(X_test_scaled)[:,1])
plt.figure()
plt.plot(fpr, tpr, label = 'AUC = %0.2f' % auc)
plt.plot([0, 1], [0, 1],'r--')
plt.xlim([0.0, 1.0])
plt.ylim([0.0, 1.05])
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.legend(loc = "lower right")
plt.savefig('Log_ROC')
plt.show()
# Получилась идеальная модель


# In[133]:


# Вычисляем среднюю ошибку, среднюю квадратичную ошибку
from sklearn import metrics

mae = metrics.mean_absolute_error(y_test, y_pred)
mse = metrics.mean_squared_error(y_test, y_pred)

print('R2 square:',metrics.r2_score(y_test, y_pred))
print('MAE: ', mae)
print('MSE: ', mse)


# In[151]:


# Определение cut-off
from numpy import sqrt
from numpy import argmax

gmeans = sqrt(tpr * (1-fpr))
ix = argmax(gmeans)
print('Cut-off = %f' % (thresholds[ix]))


# In[162]:


# Построим модель Random Forest для сравнения (параметры оставил по умолчанию, необходимо применять GridSearchCV для выбора параметров, если результаты плохие)
from sklearn.ensemble import RandomForestRegressor

rf_model = RandomForestRegressor()
rf_model.fit(X_train_scaled, y_train)


# In[172]:


y_pred_rf = rf_model.predict(X_test_scaled)

rf_model.score(X_test_scaled, y_test)


# In[175]:


auc = roc_auc_score(y_test, rf_model.predict(X_test_scaled))
fpr, tpr, thresholds = roc_curve(y_test, rf_model.predict(X_test_scaled))
plt.figure()
plt.plot(fpr, tpr, label = 'AUC = % f' % auc)
plt.plot([0, 1], [0, 1],'r--')
plt.xlim([0.0, 1.0])
plt.ylim([0.0, 1.05])
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate')
plt.legend(loc = "lower right")
plt.savefig('Log_ROC')
plt.show()
# По AUC обе модели одинаковые


# In[176]:


# Определение cut-off
from numpy import sqrt
from numpy import argmax

gmeans = sqrt(tpr * (1-fpr))
ix = argmax(gmeans)
print('Cut-off = %f' % (thresholds[ix]))
# RandomForestRegressor показывает настолько точные результаты, что превратился в классификатор (значит cut-off необходимо ставить < 1)

