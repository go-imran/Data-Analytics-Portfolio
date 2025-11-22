import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import urllib
from sqlalchemy import create_engine

# ----------------------------------------------------------
# Step 1: Build SQLAlchemy Engine
# ----------------------------------------------------------
connection_string = (
    "Driver={ODBC Driver 17 for SQL Server};"
    "Server=localhost;"          # my server name
    "Database=HR_ANALYTICS;"     # my database
    "Trusted_Connection=yes;"    # Windows Authentication
)

# URL encode the connection string
encoded_params = urllib.parse.quote_plus(connection_string)

# Create SQLAlchemy engine
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={encoded_params}")

# ----------------------------------------------------------
# Step 2: Write SQL Queries
# ----------------------------------------------------------
query_employe_data = "SELECT * FROM gold.vw_hr_employee_data"
query_training_data = "SELECT * FROM gold.vw_hr_employee_training"
query_recruitment_data = "SELECT * FROM gold.vw_hr_recruitment_data"
query_engagement_data = "SELECT * FROM gold.vw_hr_employee_engagement"

# ----------------------------------------------------------
# Step 3: Read Data into DataFrames
# ----------------------------------------------------------
df_employee = pd.read_sql(query_employe_data, engine)
df_emp_engagement = pd.read_sql(query_engagement_data, engine)
df_emp_training = pd.read_sql(query_training_data, engine)
df_emp_recruitment = pd.read_sql(query_recruitment_data, engine)


# Step 4: Preview the data

print('==================reading employee data table=========================')
print(df_employee.sort_values(by='EmpID',ascending=True).head())
print('\n')
print('==================reading employee training table=========================')
print(df_emp_training.sort_values(by='Employee ID',ascending=True).head())
print('\n')
print('================== reading employee engagement table=========================')
print(df_emp_engagement.sort_values(by='Employee ID',ascending=True).head())
print('\n')
print('==================reading employee recruitment table =========================')
print(df_emp_recruitment.sort_values(by='ApplicantID',ascending=True).head())

print('\n')
print('=====================Employee table info ================================')
print(df_employee.info())
print('\n')
print('===================== emp_engagement basic column info ================================')
print(df_emp_engagement.info())
print('\n')
print('===================== emp_recruitment tables basic column info ================================')
print(df_emp_recruitment.info())
print('\n')
print('===================== emp_trainingtables basic column info ================================')
print(df_emp_training.info())
print('\n')

#print('===============Null values count for Termination Description column==========')
#print(df_employee['Termination Description'].isnull().sum())

#print('===============FIilling null values with N/A Termination Description column==========')
#df_employee['Termination Description']=df_employee['Termination Description'].fillna('N/A')
#df_employee.to_csv(r"D:\imran\HR ANALYTICS\view_datasets-20251117T092928Z-1-001\view_datasets\vw_hr_employee_data.csv",index=False)

# -------------------------------------------
# 1. Current employee headcount by Business Unit
# -------------------------------------------
print("What is the current employee headcount by the Business Unit?")
print(df_employee.groupby("Business Unit")["EmpID"].count().reset_index(name="Total Employee").sort_values("Total Employee", ascending=False))

# -------------------------------------------
# 2. Headcount by Division
# -------------------------------------------
print(" What is the headcount by Division?")
print(df_employee.groupby("Division")["EmpID"].count().reset_index(name="Total Employee").sort_values("Total Employee", ascending=False))

# -------------------------------------------
# 3. Gender distribution across the organization
# -------------------------------------------
print("What is the gender distribution across the organization?")
print(df_employee.groupby("Gender Code")["EmpID"].count().reset_index(name="Total Employee").sort_values("Total Employee", ascending=False))

# -------------------------------------------
# 4. Age group distribution
# -------------------------------------------
print(" What is the age group distribution?")
print(df_employee.groupby("Age Group")["EmpID"].count().reset_index(name="Total Employee").sort_values("Total Employee", ascending=False))

# -------------------------------------------
# 5. Top 10 Job Titles with highest employees
# -------------------------------------------
print("Which Job Titles have the highest number of employees? (Top 10)")
print(df_employee.groupby("Job Title")["EmpID"].count().reset_index(name="Total Employee").sort_values("Total Employee", ascending=False).head(10))

# -------------------------------------------
# 6. Distribution of Employee Type (Full-Time, Contract)
# -------------------------------------------
print("What is the distribution of Employee Type (Full-Time, Contract)?")
print(df_employee.groupby("Employee Type")["EmpID"].count().reset_index(name="Total Employee").sort_values("Total Employee", ascending=False))
print('\n')

print('*************. How many employees were hired every year?********************')
df_employee['StartDate']=pd.to_datetime(df_employee['StartDate'])
df_employee['StartDate']=df_employee['StartDate'].dt.year
hired_employee=df_employee.pivot_table(values='EmpID', index='StartDate',aggfunc='count').sort_values(by='StartDate', ascending=True)\
                .reset_index()
hired_employee['Prev year employee']=hired_employee['EmpID'].shift(1)
hired_employee['New emp update']=hired_employee['EmpID']-hired_employee['Prev year employee']
hired_employee['New emp update status']=np.where(hired_employee['New emp update']>0,'Employee added',
                                                 np.where(hired_employee['New emp update']<0,'Employee left','Nothing to show')
)

print(hired_employee.fillna(0))


print(print('Null values after updation:',df_employee['Termination Description'].isnull().sum()))
print('Total N/A values Termination Description column:',(df_employee['Termination Description']=='N/A').sum())
print('\n')
print('******************How many employees are currently active vs terminated?********************')
print('Finding unique values from df_employee[Employee Status]:',df_employee['Employee Status'].unique())
#df_new=pd.DataFrame({'Active employees':[df_employee.loc[df_employee['Employee Status'] == 'Active', 'Employee Status'].count()]})
#print(df_new)
print('Activation status are given below for employees:')
print(df_employee['Employee Status'].value_counts())
print('\n')
print('******************Distribution of employees by Department, Division, Job Title, Business Unit********************')
#print(df_employee.groupby('Department Type')['EmpID'].agg('count').reset_index())
print('=========Employee count by Department Type==========================')
print(df_employee.groupby('Department Type').agg(Number_of_employees=('EmpID','count')).reset_index().sort_values(by='Number_of_employees', ascending=True))
print('\n')
print('=========Employee count by Division==========================')
print(df_employee.groupby('Division').agg(Number_of_employees=('EmpID','count')).reset_index().sort_values(by='Number_of_employees', ascending=True))
print('\n')
print('=========Employee count by Job Title ==========================')
print(df_employee.groupby('Job Title').agg(Number_of_employees=('EmpID','count')).reset_index().sort_values(by='Number_of_employees', ascending=True))
print('\n')
print('=========Employee count by Business Unit ==========================')
print(df_employee.groupby('Business Unit').agg(Number_of_employees=('EmpID','count')).reset_index().sort_values(by='Number_of_employees', ascending=True))


#sns.set(style="whitegrid")  # Optional: nicer plot style

#dept_df = df_employee.groupby('Department Type') \
 #           .agg(Number_of_employees=('EmpID','count')) \
  #          .reset_index() \
   #         .sort_values(by='Number_of_employees', ascending=True)

# plt.figure(figsize=(16,6))
#
# # Define a list of colors for the bars
# colors = ["red", "green", "blue", "orange"]
#
# # Create the bar chart
# ax = sns.barplot(
#     x='Number_of_employees',      # X-axis → number of employees
#     y='Department Type',          # Y-axis → department names
#     data=dept_df,                 # Data source
#     palette=colors                # Custom colors
# )
#
# # Add values (labels) on each bar
# for i, v in enumerate(dept_df['Number_of_employees']):
#     ax.text(
#         v + 5,                    # Position slightly right of the bar
#         i,                        # Align with the bar index position
#         str(v),                   # Display number as text
#         color='black',            # Text color
#         va='center'               # Vertically center the text
#     )
#
# # Title and labels
# plt.title("Distribution of Employees by Department")   # Chart title
# plt.xlabel("Number of Employees")                      # X-axis label
# plt.ylabel("Department")                               # Y-axis label
#
# # Display the chart
# plt.show()

print('************Average tenure by Department, Division, Job Title*******************')
print('\n')
df_employee['Tenure_years']=pd.to_datetime('today')-pd.to_datetime(df_employee['StartDate'])
df_employee['Tenure_years']=(df_employee['Tenure_years'].dt.days/365).round(0)
#pd.set_option('display.max_rows',None)
print(df_employee.groupby(['Division','Job Title']).agg(avg_tenure=('Tenure_years', 'mean')))
print('\n')

print("**********************12. How many employees exited every year? (Trend)*****************************")
status_list=['Deactive','Offer Cancelled','Voluntarily Terminated','Terminated for Cause']
df_employee['ExitDate'] = pd.to_datetime(df_employee['ExitDate'], errors='coerce')
exited_by_year=df_employee.query("`Employee Status` in @status_list").groupby(df_employee['ExitDate'].dt.year.astype('Int64')).size().sort_values(ascending=False).reset_index()
exited_by_year.columns=['Year','Exited employees']
print(exited_by_year)


print('\n')
print("*****************************13. Which Business Units have the highest attrition? (Top 5)************************************")
attrition_status = ['Voluntarily Terminated','Terminated for Cause']
attrition_grouping = (
    df_employee
    .query("`Employee Status` in @attrition_status")
    .groupby("Business Unit")
    .size()
    .sort_values(ascending=False)
    .head(5)
)
print(attrition_grouping)
print("*****************************13. Which Business Units have the highest attrition? (another way)************************************")
grouped=df_employee['Employee Status'].isin(attrition_status)
print(df_employee[grouped].value_counts(['Business Unit']).sort_values(ascending=False).head(5))

#attrition_grouping = (
 #   df_employee
    #  .loc[df_employee['Employee Status'].isin(attrition_status)]
    #  .groupby("Business Unit")
     # .size()
     # .sort_values(ascending=False)
     # .head(5)
 # )
 # print(attrition_grouping)

print('\n')

print("****************************14. Which Tenure Group has the most exits? (0–1 yrs? 1–3 yrs?)*****************************************")
status_list=['Deactive','Offer Cancelled','Voluntarily Terminated','Terminated for Cause']
exited=df_employee.query("`Employee Status` in @status_list").groupby('Tenure Group').size().sort_values(ascending=False).head(5)
Exited_table=exited.reset_index()
Exited_table.columns=['Tenure Group','Total count values']
print(Exited_table)


print('\n')

print("****************************15. What are the most common Termination Types?****************************************")
Termination_list=['Involuntary' ,'Resignation', 'Retirement', 'Voluntary']
termination_type_count=df_employee[df_employee['Termination Type'].isin(Termination_list)]
print(termination_type_count['Termination Type'].value_counts())


#termination_type_count=df_employee.query("`Termination Type` in @Termination_list")\
   # .groupby('Termination Type').size().sort_values(ascending=False).reset_index()
#termination_type_count.columns=['termination_type','termination type count']
#print(termination_type_count)


print('\n')

print("16. Which Termination Descriptions appear most frequently?")
print('\n')


print("17. What is the average tenure of employees who exit?")
Termination_list=['Involuntary' ,'Resignation', 'Retirement', 'Voluntary']
exited_series=df_employee[df_employee['Termination Type'].isin(Termination_list)]
print(exited_series['Tenure_years'].mean())

datfram=pd.DataFrame({'empid':exited_series['EmpID'], 'tenure_years':exited_series['Tenure_years']})
print('by using dataframe:',datfram['tenure_years'].mean())    

datfram = df_employee.query("`Termination Type` in @Termination_list")['Tenure_years'].mean()
datfram1 = df_employee.loc[df_employee['Termination Type'].isin(Termination_list),'Tenure_years'].mean()
print('using query',datfram)
print('using .loc[]',datfram1)

print('\n')

# 18. What is the distribution of Performance Score across employees?
print("What is the distribution of Performance Score across employees?")
print(df_employee['Performance Score'].unique())
performance_socre_distribution=df_employee.loc[df_employee['Performance Score'].isin(['Fully Meets', 'Exceeds' ,'Needs Improvement', 'Performance Improvement Plan'])].groupby('Performance Score').size()
print(performance_socre_distribution.sort_values(ascending=False))

print('\n')

# 19. What is the average Current Employee Rating by Business Unit?
print("What is the average Current Employee Rating by Business Unit?")
print(df_employee['Current Employee Rating'].unique())
ratinf_by_bus_unit= df_employee.groupby('Business Unit')['Current Employee Rating'].agg('mean').reset_index()
print(ratinf_by_bus_unit)

print('\n')

# 20. Which Divisions have the highest/lowest performance?
print("***************Which Divisions have the highest/lowest performance?")

division_performance=df_employee.groupby('Division')['Current Employee Rating'].mean().sort_values(ascending=False)
print("Division got the max rating avg:",division_performance.head(1))
print("Division got the min rating avg:",division_performance.tail(1))

print('\n')

# 21. Do younger or older age groups perform better on average?
print("Do younger or older age groups perform better on average?")
age_group_rating=df_employee.groupby('Age Group')['Current Employee Rating'].mean().sort_values(ascending=False)
print(age_group_rating.reset_index())

print('\n')

print("***********************18. What is the distribution of Performance Score across employees?**************************************")

performance_score_group=df_employee['Performance Score'].value_counts()
print(performance_score_group)

print('\n')

print('***********************22. Which training programs have the highest participation?**************************************')

high_participants=df_emp_training.groupby('Training Program Name')['Employee ID'].size().sort_values(ascending=False)
Program_name=high_participants.index[0]
value=high_participants.iloc[0]
print('Highest performance is done by:',Program_name, value)
print('\n')

print('***********************23. What is the total training cost per year?**************************************')
#print(df_emp_training['Training Date'].head(30))

df_emp_training['Training Date']=pd.to_datetime(df_emp_training['Training Date'], errors='coerce', dayfirst=True)
cost_per_year=df_emp_training.groupby([df_emp_training['Training Date'].dt.year.rename('Year'),df_emp_training['Training Date'].dt.month.rename('Month')])['Training Cost'].agg('sum').reset_index()
print(cost_per_year)

print('\n')

print('***********************24. Which employees received the most training (Top 10)?**************************************')
most_training=df_emp_training.groupby('Employee ID')['Training Type'].size().sort_values(ascending=False).reset_index()
print(most_training)
print('\n')

print('***********************25. Which Training Types are most effective (based on Training Outcome)?**************************************')
#print(df_emp_training['Training Outcome'].unique())
#Training_outcome=['Failed', 'Incomplete', 'Completed', 'Passed']
effective_program=df_emp_training.pivot_table(index=['Training Program Name'], columns=['Training Outcome'],aggfunc='size').reset_index()
effective_program['Total session']=effective_program.select_dtypes(include='number').sum(axis=1)
final_effective_program_table=effective_program[['Training Program Name','Total session','Completed','Failed','Incomplete','Passed']]
final_effective_program_table.columns.name=None
print(final_effective_program_table.head())
numeric_col=final_effective_program_table.select_dtypes(include='number')
numeric_col=numeric_col.drop(columns=['Total session'], errors='ignore')
for col in numeric_col:
    max_value=numeric_col[col].max()
    program=final_effective_program_table.loc[final_effective_program_table[col].idxmax(),'Training Program Name']
    print(f'Highest {col} program name is {program} and value is {max_value}')
        

print('***********************26. What is the average Engagement Score for each year?**************************************')

Engagement_score_yearly=df_emp_engagement.groupby('Survey Year')['Engagement Score'].mean().sort_values(ascending=False).reset_index()
print(Engagement_score_yearly)
print('\n')

print('***********************27. sort departments based on average Engagement Score?**************************************')


df_employee['EmpID'] = df_employee['EmpID'].astype(int)
df_emp_engagement['Employee ID'] = df_emp_engagement['Employee ID'].astype(int)
employe_merge_engagement=pd.merge(df_employee,df_emp_engagement, left_on='EmpID',right_on='Employee ID', how='left')
print(employe_merge_engagement.columns)
department_engagement_score=employe_merge_engagement[['Department Type','Engagement Score']]
department_engagement_score=department_engagement_score.groupby('Department Type')['Engagement Score'].mean().rename('AVG engagement score').sort_values(ascending=False)
print(department_engagement_score.reset_index())                                            



print('***********************28. What is the average Satisfaction Score by Division?**************************************')
df_employee['EmpID'] = df_employee['EmpID'].astype(int)
df_emp_engagement['Employee ID'] = df_emp_engagement['Employee ID'].astype(int)
avg_division=pd.merge(df_employee,df_emp_engagement, left_on='EmpID',right_on='Employee ID', how='left')
avg_division_pivot=avg_division.pivot_table(values='Satisfaction Score', index='Division',aggfunc="mean",fill_value=0).sort_values(by='Satisfaction Score',ascending=False).reset_index()
print(avg_division_pivot.rename(columns={'Satisfaction Score':'Avg Satisfaction Score'}))
print('\n')

print('***********************29. How does Work-Life Balance Score vary by Job Title?**************************************')
df_employee['EmpID'] = df_employee['EmpID'].astype(int)
df_emp_engagement['Employee ID'] = df_emp_engagement['Employee ID'].astype(int)
WorkLifeBalance=pd.merge(df_employee,df_emp_engagement, left_on='EmpID',right_on='Employee ID', how='left')
WorkLifeBalanceAvg=WorkLifeBalance.pivot_table(values='Work-Life Balance Score', index='Job Title', aggfunc='mean', fill_value=0)\
                    .sort_values(by='Work-Life Balance Score',ascending=False)\
                    .reset_index()\
                    .rename(columns={'Work-Life Balance Score':'Avg_WorkLifeBalance'})
print(WorkLifeBalanceAvg.head())
print('\n')

print('***********************30. What engagement level group has the highest risk (Low, Medium, High)?**************************************')
df_employee['EmpID'] = df_employee['EmpID'].astype(int)
df_emp_engagement['Employee ID'] = df_emp_engagement['Employee ID'].astype(int)
highest_risk=pd.merge(df_employee,df_emp_engagement, left_on='EmpID',right_on='Employee ID', how='left')
highest_risk=highest_risk.pivot_table(values='EmpID', index='Engagement Level', aggfunc='count').reset_index()
for col in highest_risk.select_dtypes(include='number').columns:
    in_risk=highest_risk[col].min()
    engagement_level=highest_risk.loc[highest_risk[col].idxmin(),'Engagement Level']
    print(f'{engagement_level} level has the highest risk and has only {in_risk} number employess')






